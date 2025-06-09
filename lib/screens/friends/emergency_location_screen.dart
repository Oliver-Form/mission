import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mission/utilities/firestore_helper.dart';
import 'package:mission/utilities/statics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmergencyLocationScreen extends ConsumerStatefulWidget {
  static const routeName = 'emergency-location-screen';
  const EmergencyLocationScreen({Key? key}) : super(key: key);

  @override
  EmergencyLocationScreenState createState() => EmergencyLocationScreenState();
}

class EmergencyLocationScreenState
    extends ConsumerState<EmergencyLocationScreen> {
  bool isLoading = true;
  bool isInit = true;
  LatLng currentLocation = Statics.initLocation;
  double speed = 0.0;
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1,
  );

  late String friendUID;
  late StreamSubscription<DocumentSnapshot> locationSubscription;

  Set<Marker> markers = {};

  bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  Future<void> createMyMarkers() async {
    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: currentLocation,
        infoWindow: InfoWindow(
          title: 'Current Location',
          snippet:
              'Latitude: ${currentLocation.latitude}, Longitude: ${currentLocation.longitude}',
        ),
      ),
    );
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    locationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isInit) {
      final arguments = ModalRoute.of(context)!.settings.arguments as Map;
      friendUID = arguments['friendUID'] as String;
      FirestoreHelper().getEmergencyLocation(friendUID).then((
        LatLng? location,
      ) {
        if (location != null) {
          currentLocation = location;

          createMyMarkers();
        }
      });

      locationSubscription = FirebaseFirestore.instance
          .collection('emergency')
          .doc(friendUID)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              var data = snapshot.data();
              var coordinates = data?['coordinates'];
              if (coordinates != null && coordinates is GeoPoint) {
                currentLocation = LatLng(
                  coordinates.latitude,
                  coordinates.longitude,
                );
                createMyMarkers();
              } else {
                print('No valid coordinates found for friendUID: $friendUID');
              }
            }
          });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Current Location')),
      body:
          (isLoading)
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                style: isDarkMode(context) ? Statics.darkStyle : null,
                initialCameraPosition: CameraPosition(
                  target: currentLocation, // Placeholder position
                  zoom: 10,
                ),
                markers: markers,
              ),
    );
  }
}
