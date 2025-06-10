import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mission/providers/locations_provider.dart';
import 'package:mission/providers/profile_provider.dart';
import 'package:mission/services/user_preferences.dart';
import 'package:mission/services/statics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mission/services/firestore_helper.dart';

class UserStatus {
  String status;
  String icon;
  UserStatus(this.icon, this.status);
}

@riverpod
class MyStatusProvider extends Notifier<UserStatus> {
  late var locations;
  @override
  UserStatus build() {
    return UserStatus('🔴', 'Online');
  }

  Position? prevPosition;

  Future<UserStatus> userStatus(
    LatLng currentLocation,
    double speed,
    List<RegisteredLocation> myLocations,
  ) async {
    double speedKmPH = speed; //speed maybe in km/h

    if (currentLocation.latitude == Statics.initLocation.latitude &&
        currentLocation.longitude == Statics.initLocation.longitude) {
      return UserStatus('🔴', 'offline');
    }

    for (var location in myLocations) {
      double distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        location.coordinates.latitude,
        location.coordinates.longitude,
      );
      if (distance < location.radius) {
        return UserStatus(
          location.icon,
          location.name,
        ); //in the future, we will use "status"
      }
    }
    if (speedKmPH > 60) {
      return UserStatus('🚃', 'Moving');
    } else if (speedKmPH > 20) {
      return UserStatus('🚗', 'Moving');
    } else if (speedKmPH > 6) {
      return UserStatus('🚴‍♂️', 'Moving');
    } else if (speedKmPH > 2) {
      return UserStatus('🚶‍♂️', 'Moving');
    }
    return UserStatus('🟢', 'online');
  }

  void startTrackingLocation() {
    LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Location Service is running",
          notificationText: 'mau is updating your status',
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
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
      if (position == null) {
        return;
      }
      final myLocations = ref.read(locationsProvider);
      updateMyStatus(position, myLocations);
    });
  }

  Future<void> initLocationSetting() async {
    bool permission = await Permission.location.isGranted;
    bool permissionAlways = await Permission.locationAlways.isGranted;
    bool notificationPermission = await Permission.notification.isGranted;

    if (!permission) {
      print('asking permission');
      await Permission.location.request();
    }
    if (!permissionAlways) {
      await Permission.locationAlways.request();
    }
    if (!notificationPermission) {
      await Permission.notification.request();
    }
  }

  Future<Position> getCurrentPosition() async {
    final currentPosition = await Geolocator.getCurrentPosition();
    return currentPosition;
  }

  // Future<void> sendArrivalNotification(String status) async {
  //   final myProfile = ref.read(profileProvider);
  //   final senderImageUrl = myProfile.iconLink ?? Statics.defaultIconLink;
  //   final senderName = myProfile.name ?? 'username';

  //   FirestoreHelper().addMessage(
  //     title: 'Arrival',
  //     body: '${senderName} is now in $status',
  //     imageUrl: senderImageUrl,
  //     type: 'Arrival',
  //     receivers: receivers
  //   );
  // } //keep user's basic profile

  Future<void> updateMyStatus(
    Position position,
    List<RegisteredLocation> myLocations,
  ) async {
    final currentLocation = LatLng(position.latitude, position.longitude);
    //save in firebase and riverpod
    var status = await userStatus(currentLocation, position.speed, myLocations);
    if (status.icon == state.icon && status.status == state.status) {
      return;
    } else {
      state = status;
      FirestoreHelper().updateStatus(status);
    }
  }
}

final myStatusProvider = NotifierProvider<MyStatusProvider, UserStatus>(
  MyStatusProvider.new,
);
