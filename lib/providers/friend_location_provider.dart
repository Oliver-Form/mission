import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mission/services/firestore_helper.dart';

class Location {
  final LatLng latlng;
  final Timestamp timestamp;

  Location({required this.latlng, required this.timestamp});
}

class FriendLocationProvider extends Notifier<Map<String, Location>> {
  @override
  Map<String, Location> build() => {};

  Future<void> loadFriendLocations() async {
    Map<String, Location> locationMap = await FirestoreHelper().getAllFriendLocations();
    state = locationMap;
  }

  Future<void> startListeningToFriendLocations() async {
    final myUID = FirebaseFirestore.instance.collection('locations').doc().id;
    final friendLocationsStream = FirestoreHelper().getFriendLocationsStream(myUID);

    friendLocationsStream.listen((snapshot) {
      Map<String, Location> newLocationMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        
        if (data != null) {
          newLocationMap[doc.id] = Location(
            latlng: LatLng(data['coordinates'].latitude, data['coordinates'].longitude), // may need to be changed
            timestamp: data['timestamp'],
          );
        }
      }
      state = newLocationMap;
    });
  }
}

final friendLocationProvider =
    NotifierProvider<FriendLocationProvider, Map<String, Location>>(
      FriendLocationProvider.new,
    );
