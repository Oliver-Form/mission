import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mission/services/user_preferences.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({Key? key}) : super(key: key);

  @override
  _LocationsPageState createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  final Set<Marker> _markers = {};
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _initLocationAndName();
  }

  Future<void> _initLocationAndName() async {
    final name = UserPreferences.getName() ?? 'Me';
    await _ensurePermission();
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final latLng = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _userName = name;
      _currentLatLng = latLng;
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: latLng,
          infoWindow: InfoWindow(title: _userName),
        ),
      );
    });
  }

  Future<void> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      // Permissions are denied, you might want to show a dialog
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLatLng == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLatLng!,
        zoom: 15,
      ),
      markers: _markers,
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

