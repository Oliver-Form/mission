import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mission/providers/locations_provider.dart';
import 'dart:developer';

import 'package:mission/utilities/statics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;

class CurrentLocationScreen extends ConsumerStatefulWidget {
  static const routeName = 'current-location-screen';
  const CurrentLocationScreen({Key? key}) : super(key: key);

  @override
  _CurrentLocationScreenState createState() => _CurrentLocationScreenState();
}

class _CurrentLocationScreenState extends ConsumerState<CurrentLocationScreen> {
  bool isLoading = true;
  bool isInit = true;
  LatLng currentLocation = Statics.initLocation;
  double speed = 0.0;
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1,
  );

  late StreamSubscription<Position> positionStream;
  Set<Marker> markers = {};
  bool isLoadingMarkers = true;

  bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  @override
  void initState() {
    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position? position) {
      if (position == null) {
        return;
      }
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        speed = position.speed;
      });
    });
    super.initState();
  }

  Future<BitmapDescriptor> createEmojiMarker(String emoji) async {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Create a Text widget with the emoji
    textPainter.text = TextSpan(
      text: emoji,
      style: const TextStyle(
        fontSize: 50, // Adjust size as needed
      ),
    );

    textPainter.layout();
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Add padding and calculate size
    const double padding = 20.0;
    final double size =
        (textPainter.width > textPainter.height
            ? textPainter.width
            : textPainter.height) +
        padding * 2;

    // Add a white circle background
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Add an outline around the circle
    final outlinePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.0;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, outlinePaint);

    // Draw the emoji on top of the circle
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<void> createMyMarkers() async {
    final mylocations = ref.watch(locationsProvider);
    for (var location in mylocations) {
      final marker = Marker(
        markerId: MarkerId(location.name),
        position: LatLng(
          location.coordinates.latitude,
          location.coordinates.longitude,
        ),
        icon: await createEmojiMarker(location.icon),
        infoWindow: InfoWindow(title: location.name),
      );
      markers.add(marker);
    }
    setState(() {
      isLoadingMarkers = false;
    });
  }

  Set<Circle> createMyPolygons() {
    final mylocations = ref.watch(locationsProvider);
    Set<Circle> polygons = {};
    for (var location in mylocations) {
      final polygon = Circle(
        radius: location.radius.toDouble(),
        circleId: CircleId(location.name),
        center: LatLng(
          location.coordinates.latitude,
          location.coordinates.longitude,
        ),
        strokeWidth: 2,
      );
      polygons.add(polygon);
    }
    return polygons;
  }

  @override
  void dispose() {
    positionStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isInit) {
      createMyMarkers();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Current Location')),
      body:
          (isLoading && isLoadingMarkers)
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                style: isDarkMode(context) ? Statics.darkStyle : null,
                initialCameraPosition: CameraPosition(
                  target: Statics.initLocation, // Placeholder position
                  zoom: 2,
                ),
                circles: createMyPolygons(),
                markers: markers,
              ),
    );
  }
}
