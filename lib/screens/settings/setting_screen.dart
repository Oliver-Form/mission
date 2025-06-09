import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mission/screens/welcome/authGate.dart';
import 'package:mission/screens/settings/current_location_screen.dart';
import 'package:mission/screens/settings/profile_setting_screen.dart';

class SettingScreen extends StatefulWidget {
  static const routeName = '/settings';
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String username = 'Username';
  String bio = 'Bio goes here...';
  String profileImage = 'assets/profile_placeholder.png'; // Replace with actual image

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit Profile'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  ProfileSettingScreen.routeName,
            );
              },
            ),
            
            ListTile(
              title: Text('Current Location'),
              leading: Icon(Icons.location_on_outlined),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  CurrentLocationScreen.routeName,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log Out'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(
                  context,
                  AuthGate.routeName,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}