import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Emergency {
  final bool isEmergency;
  final Timestamp timestamp;

  Emergency({
    required this.isEmergency,
    required this.timestamp,
  });

  
}

class EmergencyNotifier extends StateNotifier<Emergency> {
  EmergencyNotifier()
      : super(Emergency(isEmergency: false, timestamp: Timestamp.now()));

  void activateEmergency() {
    state = Emergency(isEmergency: true, timestamp: Timestamp.now());
  }

  void deactivateEmergency() {
    state = Emergency(isEmergency: false, timestamp: Timestamp.now());
  }
  bool isEmergencyActive() {
    return state.isEmergency &&
        state.timestamp.toDate().isAfter(
          DateTime.now().subtract(const Duration(hours: 1)),
        );
  }
}

final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, Emergency>((ref) {
  return EmergencyNotifier();
});