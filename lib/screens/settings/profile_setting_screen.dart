import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mission/providers/friend_list_provider.dart';

import 'package:mission/providers/profile_provider.dart';
import 'package:mission/screens/overview_page.dart';
import 'package:mission/screens/welcome/authGate.dart';
import 'package:mission/utilities/firestore_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mission/providers/profile_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mission/utilities/statics.dart';

import 'dart:io';


class ProfileSettingScreen extends ConsumerStatefulWidget {
  static const routeName = '/profile-setting';
  final bool isNewUser;
  const ProfileSettingScreen({Key? key, this.isNewUser = false})
    : super(key: key);
  @override
  _ProfileSettingScreenState createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends ConsumerState<ProfileSettingScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _selectedIcon;
  File? iconImage;
  bool setImage = false;
  bool isLoading = false;
  bool isDeleteLoading = false;
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();


    final profile = ref.read(profileProvider);
    _usernameController.text = profile.name ?? '';
    _bioController.text = profile.bio ?? '';
    _selectedIcon = profile.iconLink;
    if (widget.isNewUser) {
      _usernameController.text = '';
      _bioController.text = '';
      _selectedIcon = null;
    }
  }

  Future<void> _saveProfileSettings() async {
    setState(() {
      isLoading = true;
    });
    String username = _usernameController.text;
    String bio = _bioController.text;
    String userUID = FirebaseAuth.instance.currentUser!.uid;

    //upload icon image
    String uploadPath = 'users/$userUID/icon.png';
    String iconLink = '';

    if (iconImage != null) {
      iconLink = await StorageHelper().uploadFile(uploadPath, iconImage!);
    } else {
      iconLink = _selectedIcon ?? '';
    }
    //FCM token

    //save to firestores
    await FirestoreHelper().addUserProfile(userUID, username, bio, iconLink);
    ref.read(profileProvider.notifier).loadMyProfile();
    setState(() {
      isLoading = false;
    });
    if (widget.isNewUser) {
      Navigator.of(context).pushNamed(OverviewPage.routeName);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectIcon() async {
    var result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null) {
      var path = result.files.single.path!;
      var originalIconImage = File(path);

      //compress image
      var originalSize = originalIconImage.lengthSync();
      var targetSize = 100000; //300KB
      if (originalSize > targetSize) {
        var quality = ((targetSize / originalSize) * 100).toInt();
        List<int> compressedImage =
            (await FlutterImageCompress.compressWithFile(
                  path,
                  minWidth: 300,
                  minHeight: 300,
                  quality: quality,
                ))
                as List<int>;
        iconImage = File(path)..writeAsBytesSync(compressedImage);
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String compressedPath = '${appDocDir.path}/compressed_icon.png';
        await File(compressedPath).writeAsBytes(compressedImage);
        iconImage = File(compressedPath);
      } else {
        iconImage = originalIconImage;
      }
      setState(() {
        setImage = true;
      });
    }
  }

  // 全画面プログレスダイアログを表示する関数
  void showProgressDialog(context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration.zero, // これを入れると遅延を入れなくて
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (
        BuildContext context,
        Animation animation,
        Animation secondaryAnimation,
      ) {
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> reauthenticate(User? user) async {
    AuthCredential? credential;
    if (user != null) {
      for (final providerProfile in user.providerData) {
        switch (providerProfile.providerId) {
          case 'google.com':
            final googleUser = await GoogleSignIn().signIn();
            final googleAuth = await googleUser!.authentication;
            credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            break;
          case 'password':
            String password = '';

            final _formKey = GlobalKey<FormState>();
            String tempPassword = '';
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return isDeleteLoading
                    ? Center(child: CircularProgressIndicator())
                    : Container(
                      height: 700,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          left: 25,
                          right: 25,
                          top: 50,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Re-authenticate',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              SizedBox(height: 25),
                              TextField(
                                enabled: false,
                                controller: TextEditingController(
                                  text: user.email,
                                ),
                                decoration: InputDecoration(labelText: 'Email'),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  tempPassword = value;
                                },
                              ),
                              SizedBox(height: 30),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    password = tempPassword;
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 50,
                                    vertical: 15,
                                  ),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
              },
            );

            credential = EmailAuthProvider.credential(
              email: user.email!,
              password: password, // Prompt the user for their password
            );
            break;
          case 'apple.com':
            await FirebaseAuth.instance.currentUser!.reauthenticateWithProvider(
              AppleAuthProvider(),
            );
            break;
        }
      }
    }
    if (credential != null) {
      user!.reauthenticateWithCredential(credential);
    }
  }

  Future<void> deleteAccount() async {
    final userUID = FirebaseAuth.instance.currentUser!.uid;
    final friendList = ref.read(friendListProvider);

    User? user = FirebaseAuth.instance.currentUser;
    try {
      await reauthenticate(user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Re-authentication failed. Try again.'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    showProgressDialog(context);
    //delete
    for (var uid in friendList) {
      FirestoreHelper().removeFriend(uid);
    }
    FirestoreHelper().deleteUserProfile(userUID);
    RealtimeDatabaseHelper().deleteStatus();
    FirestoreHelper().deleteFriendList();
    await user!.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account deleted successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
        actions: [
          ElevatedButton(
            onPressed: _saveProfileSettings,
            child: isLoading ? CircularProgressIndicator() : Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text('Icon', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: _selectIcon,
                    icon: Icon(Icons.add_a_photo_outlined),
                    label: Text('Choose Image'),
                  ),
                ],
              ),

              if (_selectedIcon != null && !setImage) ...[
                SizedBox(width: 10),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    _selectedIcon ??
                        Statics.defaultIconLink, // default icon link
                  ),
                ), // a
              ],
              if (setImage) ...[
                SizedBox(width: 30),

                SizedBox(
                  height: 100,
                  width: 100,
                  child: ClipOval(
                    child:
                        (iconImage != null)
                            ? Image.file(
                              iconImage!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                ),
              ],
              SizedBox(height: 40),
              TextField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 30),
              Center(
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Delete Account'),
                          content:
                              (isDeleteLoading)
                                  ? Center(child: CircularProgressIndicator())
                                  : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'All data including your profile, friends, and locations will be deleted.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'You may be required to sign-in again.',
                                      ),
                                    ],
                                  ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await deleteAccount();
                                Navigator.of(
                                  context,
                                ).pushNamed(AuthGate.routeName);
                              },
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Delete Account'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
