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
}