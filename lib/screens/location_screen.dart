import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mission/providers/friend_location_provider.dart';
import 'package:mission/providers/profile_provider.dart';
import 'package:mission/services/firestore_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mission/services/location_helper.dart';
import 'package:mission/services/statics.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class LocationScreen extends ConsumerStatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  String _location = "Unknown";
  bool isMarkerLoading = true;
  LatLng currentPosition = Statics.initLocation;
  Set<Marker> markersSet = {};

  @override
  void initState() {
    super.initState();
    createFriendMarkers(ref.read(friendLocationProvider));
    print('friendProfiles: ${ref.read(friendProfilesProvider)}');
  }

  Future<Uint8List?> getMarkerImage(String imageUrl) async {
    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      return response.bodyBytes;
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }
  Future<BitmapDescriptor?> createMarkerIcon(String imageUrl) async {
    final Uint8List? imageBytes = await getMarkerImage(imageUrl);
    if (imageBytes == null) return null;
    return BitmapDescriptor.fromBytes(imageBytes);
  }

  Future<void> createFriendMarkers(friendLocations) async {
    print('friendLocation: $friendLocations');
    markersSet = {};
    currentPosition = await LocationHelper().getCurrentPosition();

    for (var entry in friendLocations.entries) {
      final friendUID = entry.key;
      final location = entry.value.latlng;
      final timestamp = entry.value.timestamp;

      final friendProfile = ref.read(friendProfilesProvider)[friendUID];
      print('iconLink: ${friendProfile?.iconLink}');
       final BitmapDescriptor? markerIcon = await createMarkerIcon(
        friendProfile?.iconLink ?? Statics.defaultIconLink,
      );
      markersSet.add(
        Marker(
          markerId: MarkerId(friendUID),
          position: location ?? Statics.initLocation,
          icon: markerIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
        title: friendProfile?.name ?? '',
        snippet: 'Last update: ${timestamp?.toDate()}',
          ),
        ),
      );
    }
    setState(() {
      isMarkerLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void startTrackingLocation() {
    LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Location Service is running",
          notificationText: 'mau is updating your status',
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        distanceFilter: 50,
        accuracy: LocationAccuracy.high,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position? position,
    ) {
      print(position);
      setState(() {
        if (position == null) {
          _location = "Unknown";
        } else {
          _location = "lat:${position.latitude}, long:${position.longitude}";
          FirestoreHelper().updateLocation(
            LatLng(position.latitude, position.longitude),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var friendLocations = ref.watch(friendLocationProvider);
    ref.listen(friendLocationProvider, (previous, next) {
      if (next != previous) {
        createFriendMarkers(next);
      }
    });
    print(friendLocations);
    return Scaffold(
      appBar: AppBar(title: Text('Location Screen')),
      body: isMarkerLoading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentPosition,
                zoom: 14.0,
              ),
              markers: markersSet,
            ),
    );
  }
}
