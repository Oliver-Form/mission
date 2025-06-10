import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHelper {
    Future<void> initLocationSetting() async {
    bool permission = await Permission.location.isGranted;
    bool permissionAlways = await Permission.locationAlways.isGranted;
    bool notificationPermission = await Permission.notification.isGranted;

    if (!permission) {
      await Permission.location.request();
    }
    if (!permissionAlways) {
      await Permission.locationAlways.request();
    }
    if (!notificationPermission) {
      await Permission.notification.request();
    }
  }
  
  Future<LatLng> getCurrentPosition() async {

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }
}