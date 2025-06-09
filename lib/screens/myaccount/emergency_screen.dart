import 'dart:async';
import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:mission/providers/emergency_provider.dart';
import 'package:mission/providers/profile_provider.dart';
import 'package:mission/utilities/firestore_helper.dart';
import 'package:mission/utilities/prefs_helper.dart';
import 'package:mission/utilities/statics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  static const String routeName = '/emergency';
  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  LatLng currentLocation = Statics.initLocation;
  bool isLocationSharing = false;

  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );
  Marker? currentMarker;
  bool isMapLoading = true;
  bool isLocationSharingEnabled = false;
  String receiverNames = '';
  late StreamSubscription positionStream;
  LocationSettings locationSettings() {
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
    return locationSettings;
  }

  @override
  void initState() {
    super.initState();
    isLocationSharingEnabled = ref
        .read(emergencyProvider.notifier)
        .isEmergencyActive();
    Geolocator.getCurrentPosition().then((position) {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        initialCameraPosition = CameraPosition(
          target: currentLocation,
          zoom: 14,
        );
        currentMarker = Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLocation,
        );
        isMapLoading = false;
      });
    });

    positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings(),
        ).listen((Position? position) {
          if (position != null) {
            setState(() {
              currentLocation = LatLng(position.latitude, position.longitude);
              initialCameraPosition = CameraPosition(
                target: currentLocation,
                zoom: 14,
              );
              currentMarker = Marker(
                markerId: const MarkerId('currentLocation'),
                position: currentLocation,
              );
            });
          }
        });

    PrefsHelper().getEmergencyPrefs().then((receivers) {
      if (receivers.isNotEmpty) {
        setState(() {
          List receiverNameList = [];
          for (var receiverUID in receivers) {
            if (receiverUID.isEmpty) continue; // Skip empty tokens
            final profile = ref.read(friendProfilesProvider)[receiverUID];
            if (profile == null) continue; // Skip if profile not found)
            receiverNameList.add(profile.name ?? 'Unknown');
          }
          receiverNames = receiverNameList.join(', ');
        });
      } else {
        setState(() {
          receiverNames = '(No emergency contacts set.)';
        });
      }
    });
  }

  @override
  void dispose() {
    positionStream.cancel();
    super.dispose();
  }

  bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  Future<void> startSharingLocation() async {
    setState(() {
      isLocationSharing = true;
    });
    final myProfile = ref.read(profileProvider);
    final myname = myProfile.name ?? 'Your friend';
    final title = '$myname Feeling Unsafe';
    final imageUrl = myProfile.iconLink ?? Statics.defaultIconLink;
    final body = '$myname started emergency location sharing.';
    final receivers = await PrefsHelper().getEmergencyPrefs();

    FirestoreHelper().addMessage(
      title: title,
      body: body,
      imageUrl: imageUrl,
      type: 'Emergency',
      receivers: receivers,
    );
    FirestoreHelper().addEmergencyLocation(currentLocation);
    ref.read(emergencyProvider.notifier).activateEmergency();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? null : Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Feeling Unsafe',
          style: TextStyle(color: Colors.red.shade600),
        ),
        backgroundColor: isDarkMode(context) ? null : Colors.grey.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                "Share current location",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                "Your exact location will be sent to:\n$receiverNames",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: AnimatedToggleSwitch.dual(
                  animationDuration: const Duration(milliseconds: 300),

                  first: false,
                  second: true,
                  indicatorSize: const Size(60, 60),
                  height: 80,
                  borderWidth: 10,
                  style: ToggleStyle(
                    indicatorColor: isLocationSharingEnabled
                        ? Colors.white
                        : Colors.red.shade600,
                    borderColor: isLocationSharingEnabled
                        ? Colors.red.shade600
                        : Colors.white,
                    backgroundColor: isLocationSharingEnabled
                        ? Colors.red.shade600
                        : Colors.white,
                  ),
                  iconBuilder: (value) => value
                      ? Icon(Icons.stop, color: Colors.black, size: 30)
                      : Icon(
                          Icons.location_on_outlined,
                          color: Colors.black,
                          size: 30,
                        ),
                  textBuilder: (value) => Text(
                    value ? "Stop Sharing" : "Share Location",
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                  current: isLocationSharingEnabled,
                  onChanged: (value) {
                    setState(() {
                      isLocationSharingEnabled = value;
                    });
                    if (value) {
                      startSharingLocation();
                    } else {
                      ref
                          .read(emergencyProvider.notifier)
                          .deactivateEmergency();
                      FirestoreHelper().removeEmergencyLocation();
                    }
                  },
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 300,
                child: (isMapLoading)
                    ? Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        style: isDarkMode(context) ? Statics.darkStyle : null,
                        initialCameraPosition: initialCameraPosition,
                        markers: {currentMarker!},
                      ),
              ),
              const SizedBox(height: 60),
              // Text(
              //   "Send Circumstances",
              //   style: Theme.of(context).textTheme.headlineMedium,
              // ),
              // const SizedBox(height: 10),
              // Text(
              //   "You can send video (~ 1 min) of your current situation to your emergency close friends.",
              //   style: Theme.of(context).textTheme.bodyMedium,
              // ),
              // const SizedBox(height: 20),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 50),
              //   child: SlideAction(
              //     height: 80,
              //     elevation: 0,
              //     text: 'Send Video',
              //     textStyle: TextStyle(color: Colors.black, fontSize: 18),
              //     outerColor: Colors.white,
              //     innerColor: Colors.red.shade600,
              //     sliderButtonIcon: Icon(
              //       size: 30,

              //       Icons.videocam_outlined,
              //       weight: 30,

              //       color: Colors.black,
              //     ),
              //     onSubmit: () {
              //       // Handle the action when the button is slid
              //       print('Location sent');
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
