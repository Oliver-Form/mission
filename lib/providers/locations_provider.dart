import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mission/services/database_helper.dart';

class RegisteredLocation {
  final String name;
  final String icon;
  final LatLng coordinates;
  final int radius;
  RegisteredLocation(this.name, this.icon, this.coordinates, this.radius);
}

@riverpod
class LocationsProvider extends Notifier<List<RegisteredLocation>> {
  @override
  List<RegisteredLocation> build() => [];

  //riverpod
  Future<void> updateLocations(List<RegisteredLocation> locations) async {
    //save to riverpod
    state = locations;
  }

  Future<void> loadLocations() async {
    MyLocationDatabaseHelper dbHelper = MyLocationDatabaseHelper();

    var result = await dbHelper.getAllData();
    var output = <RegisteredLocation>[];
    if (result != null &&result.isNotEmpty) {
      result.forEach((element) {
        var coordinates = LatLng(element['latitude'], element['longitude']);
        var name = element['name'];
        var icon = element['icon'];
        var radius = element['radius'];

        output.add(RegisteredLocation(name, icon, coordinates, radius));
      });
      state = output;
    } else {
      state = [];
    }
  }
}

final locationsProvider =
    NotifierProvider<LocationsProvider, List<RegisteredLocation>>(
      LocationsProvider.new,
    );
