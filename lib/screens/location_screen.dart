import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mission/services/location_helper.dart';


class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _location = "Unknown";

  @override
  void initState() {
    super.initState();
    LocationHelper().initLocationSetting().then((_) {
      startTrackingLocation();
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
        }
           });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Location:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
              _location,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
