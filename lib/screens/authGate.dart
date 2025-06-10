import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mission/main.dart';
import 'package:mission/screens/profile_setting_screen.dart';

class AuthGate extends ConsumerWidget {
  static const routeName = 'auth-gate';
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var clientId;
    if (Platform.isIOS) {
      clientId = dotenv.env['Auth_Google_client_id_iOS'];
    } else {
      clientId = dotenv.env['Auth_Google_client_id'];
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              //GoogleProvider(clientId: clientId),
              // AppleProvider(),
              EmailAuthProvider(),
            ],
          );
        }
        if (snapshot.data!.metadata.creationTime ==
            snapshot.data!.metadata.lastSignInTime) {
          return ProfileSettingScreen(isNewUser: true);
        }
        return MyHomePage();
      },
    );
  }
}
