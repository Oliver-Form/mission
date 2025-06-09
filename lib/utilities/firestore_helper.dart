import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mission/providers/my_status_provider.dart';
import 'package:mission/utilities/prefs_helper.dart';

class FirestoreHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a document to a collection
  Future<void> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collectionPath).add(data);
    } catch (e) {
      print('Error adding document: $e');
      rethrow;
    }
  }

  Future<void> addMutedList(String friendUID) async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _firestore.collection('userProfiles').doc(myUID).set({
        'mutedList': FieldValue.arrayUnion([friendUID]),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error adding to muted list: $e');
      rethrow;
    }
  }

  Future<void> removeMutedList(String friendUID) async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _firestore.collection('userProfiles').doc(myUID).update({
        'mutedList': FieldValue.arrayRemove([friendUID]),
      });
    } catch (e) {
      print('Error removing from muted list: $e');
      rethrow;
    }
  }

  // Get all documents from a collection
  Future<Map<String, dynamic>> getUserProfile(String userUID) async {
    try {
      final userDoc =
          await _firestore.collection('userProfiles').doc(userUID).get();

      return userDoc.data() ?? {};
    } catch (e) {
      print('Error getting documents: $e');
      rethrow;
    }
  }

  Future<String> getUIDFromUsername(String username) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('userProfiles')
              .where('username', isEqualTo: username)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id; // Return the first matching UID
      } else {
        return ''; // No matching user found
      }
    } catch (e) {
      print('Error getting UID from username: $e');
      rethrow;
    }
  }

  Future<void> addEmergencyLocation(LatLng coordinates) async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    var receivers = await PrefsHelper().getEmergencyPrefs();
    return _firestore.collection('emergency').doc(myUID).set({
      'coordinates': GeoPoint(coordinates.latitude, coordinates.longitude),
      'timestamp': FieldValue.serverTimestamp(),
      'receivers': receivers,
    }, SetOptions(merge: true));
  }

  Future<LatLng?> getEmergencyLocation(String friendUID) async {
    final emergencyDoc =
        await _firestore.collection('emergency').doc(friendUID).get();
    if (emergencyDoc.exists) {
      var data = emergencyDoc.data();
      if (data != null) {
        var timestamp = data['timestamp'];
        var receivers = data['receivers'];

        if (timestamp != null && timestamp is Timestamp) {
          // Check if the timestamp is within the last 1 hour
          if (timestamp.toDate().isBefore(
            DateTime.now().subtract(Duration(hours: 1)),
          )) {
            return null; // Data is too old, return null
          }
        }
        if (receivers != null && receivers is List) {
          // Check if the current user is in the receivers list
          var myUID = FirebaseAuth.instance.currentUser!.uid;
          if (!receivers.contains(myUID)) {
            return null; // Current user is not a receiver, return null
          }
        }
        GeoPoint geoPoint = data['coordinates'];
        return LatLng(geoPoint.latitude, geoPoint.longitude);
      }
    }
    return null;
  }

  Future<void> removeEmergencyLocation() async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _firestore.collection('emergency').doc(myUID).delete();
    } catch (e) {
      print('Error removing emergency location: $e');
      rethrow;
    }
  }

  Future<void> addUserProfile(
    String userUID,
    String? username,
    String? bio,
    String? iconLink,
  ) async {
    try {
      var data = {
        'userUID': userUID,
        'username': username,
        'bio': bio,
        'iconLink': iconLink,
      };
      await _firestore.collection('userProfiles').doc(userUID).set(data);
    } catch (e) {
      print('Error adding user profile: $e');
      rethrow;
    }
  }

  Future<void> deleteUserProfile(String userUID) async {
    await _firestore.collection('userProfiles').doc(userUID).delete();
  }

  Future<void> updatePassword(String userUID, String password) async {
    await _firestore.collection('userPasswords').doc(userUID).set({
      'password': password,
    }, SetOptions(merge: true));
  }

  Future<String> getPassword(String userUID) async {
    try {
      final passwordDoc =
          await _firestore.collection('userPasswords').doc(userUID).get();
      return passwordDoc.data()?['password'] ?? '';
    } catch (e) {
      print('Error getting password: $e');
      rethrow;
    }
  }

  Future<void> updatePermanentAddress(
    String userUID,
    String permanentAddress,
  ) async {
    try {
      await _firestore.collection('userPasswords').doc(userUID).set({
        'permanentAddress': permanentAddress,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating permanent address: $e');
      rethrow;
    }
  }

  Future<String> getPermanentAddress(String userUID) async {
    try {
      final addressDoc =
          await _firestore.collection('userPasswords').doc(userUID).get();
      print('permanent address: ${addressDoc.data()}');
      return addressDoc.data()?['permanentAddress'] ?? '';
    } catch (e) {
      print('Error getting permanent address: $e');
      rethrow;
    }
  }

  Future<void> addFriendList(String friendUID) async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    final myProfile = await getUserProfile(myUID);
    final friendProfile = await getUserProfile(friendUID);

    final oldFriendList = await getFriendList();
    if (oldFriendList.isEmpty) {
      //addFirstFriendToken(friendUID);
    }
    //update my firestore
    try {
      await _firestore.collection('friendList').doc(myUID).set({
        'friendList': FieldValue.arrayUnion([friendUID]),
      }, SetOptions(merge: true));
      await _firestore.collection('friendList').doc(myUID).set({
        'profiles': {friendUID: friendProfile},
      }, SetOptions(merge: true));

      //update friend's firestore
      await _firestore.collection('friendList').doc(friendUID).set({
        'friendList': FieldValue.arrayUnion([myUID]),
      }, SetOptions(merge: true));
      await _firestore.collection('friendList').doc(friendUID).set({
        'profiles': {myUID: myProfile},
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error adding friend: $e');
      rethrow;
    }
  }


  Future<List<String>> getFriendList() async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      final friendListDoc =
          await _firestore.collection('friendList').doc(myUID).get();
      List<String> friendList = List<String>.from(
        friendListDoc.data()?['friendList'] ?? [],
      );
      return friendList;
    } catch (e) {
      print('Error getting friend list: $e');
      rethrow;
    }
  }

  

  Future<void> updateFriendList(List<String> friendList) async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _firestore.collection('friendList').doc(myUID).set({
        'friendList': friendList,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating friend list: $e');
      rethrow;
    }
  }

  Future<void> deleteFriendList() async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection('friendList').doc(myUID).delete();
  }

  Future<void> removeFriend(String friendUID) async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _firestore.collection('friendList').doc(myUID).update({
        'friendList': FieldValue.arrayRemove([friendUID]),
      });
      await _firestore.collection('friendList').doc(friendUID).update({
        'friendList': FieldValue.arrayRemove([myUID]),
      });
    } catch (e) {
      print('Error removing friend: $e');
      rethrow;
    }
  }

  Future<Map> getFriendProfiles() async {
    try {
      String myUID = FirebaseAuth.instance.currentUser!.uid;
      final friendDoc =
          await _firestore.collection('friendList').doc(myUID).get();

      var data = friendDoc.data();
      var result = {};
      if (data != null) {
        result = data['profiles'];
      } else {
        result = {};
      }

      return result;
    } catch (e) {
      print('Error loading friend profiles: $e');
      rethrow;
    }
  }

  Future<void> removeFriendProfile(String friendUID) async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      //remove friend profile from my firestore
      var docRef = _firestore.collection('friendList').doc(myUID);
      var docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        Map profiles = docSnapshot.data()?['profiles'] ?? {};
        profiles.remove(friendUID);
        await docRef.update({'profiles': profiles});
      }
      //remove my profile from friend's firestore
      var friendDocRef = _firestore.collection('friendList').doc(friendUID);
      var friendDocSnapshot = await friendDocRef.get();
      if (friendDocSnapshot.exists) {
        Map profiles = friendDocSnapshot.data()?['profiles'] ?? {};
        profiles.remove(myUID);
        await friendDocRef.update({'profiles': profiles});
      }
    } catch (e) {
      print('Error removing friend profile: $e');
      rethrow;
    }
  }

  Future<void> addMessage(
    {
    required String title,
    required String body,
    required String imageUrl,
    required String type,
    required List<String> receivers,
    String? message,
  }
    
  ) async {
    final senderUID = FirebaseAuth.instance.currentUser!.uid;

    List<String> receiverTokens = [];
    for (var receiverUID in receivers) {
      if (receiverUID.isEmpty) continue; // Skip empty tokens
      final profile = await FirestoreHelper().getUserProfile(receiverUID);
      final token = profile['fcmToken'] ?? '';
      final mutedList = profile['mutedList'] ?? [];
      if (mutedList.contains(senderUID) || token.isEmpty) {
        continue; // Skip if sender is muted or token is empty
      }

      receiverTokens.add(token);
    }
    if (receiverTokens.isEmpty) {
      print('No valid receiver tokens found for notification.');
      return; // No valid tokens to send notification
    }
    try {
      await _firestore.collection('message').doc().set({
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'senderUID': senderUID,
        'receiverTokens': receiverTokens,
        'timestamp': FieldValue.serverTimestamp(),
      });

      //add notification
      await addNotification(title, body, imageUrl, type, receivers, senderUID, message: message);
    } catch (e) {
      print('Error adding message: $e');
      rethrow;
    }
  }

  Future<void> addNotification(
    String title,
    String body,
    String imageUrl,
    String type,
    List<String> receivers,
    String senderUID,
    {String? message}
  ) async {
    final timestamp = Timestamp.now();
    for (String receiver in receivers) {
      await _firestore.collection('notifications').doc(receiver).set({
        'notifications': FieldValue.arrayUnion([
          {
            'title': title,
            'body': body,
            'imageUrl': imageUrl,
            'type': type,
            'senderUID': senderUID,
            'receiverTokens': receivers,
            'timestamp': timestamp,
            'message': message ?? '',
          },
        ]),
      }, SetOptions(merge: true));
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    String myUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      final notificationDoc =
          await _firestore.collection('notifications').doc(myUID).get();
      List<Map<String, dynamic>> notifications =
          List<Map<String, dynamic>>.from(
            notificationDoc.data()?['notifications'] ?? [],
          );
      // Sort notifications by timestamp in descending order
      notifications.sort((a, b) {
        Timestamp? aTimestamp = a['timestamp'];
        Timestamp? bTimestamp = b['timestamp'];
        if (aTimestamp == null || bTimestamp == null) return 0;
        return bTimestamp.compareTo(aTimestamp);
      });
      return notifications;
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  // Future<void> addFirstFriendToken(String friendUID) async {
  //   final token = await FirebaseMessaging.instance.getToken();
  //   _firestore.collection('friendList').doc(friendUID).set({
  //     'firstFriendTokenList': FieldValue.arrayUnion([token]),
  //   }, SetOptions(merge: true));
  //   print('FCM token for $friendUID added successfully.');
  // }

  // Future<void> removeFirstFriendToken(String friendUID) async {
  //   final token = await FirebaseMessaging.instance.getToken();
  //   if (token != null) {
  //     _firestore.collection('friendList').doc(friendUID).update({
  //       'firstFriendTokenList': FieldValue.arrayRemove([token]),
  //     });
  //     print('FCM token for $friendUID removed successfully.');
  //   } else {
  //     print('No valid FCM token found for $friendUID');
  //   }
  // }
}

class StorageHelper {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a file to Firebase Storage
  Future<String> uploadFile(String uploadPath, File file) async {
    try {
      final ref = _storage.ref().child(uploadPath);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  // Download a file from Firebase Storage
  Future<void> downloadFile(String url, String localPath) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.writeToFile(File(localPath));
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }
}

class RealtimeDatabaseHelper {
  FirebaseDatabase database = FirebaseDatabase.instance;

  Future<void> updateStatus(UserStatus status) async {
    var userUID = FirebaseAuth.instance.currentUser!.uid;
    await database.ref('users/$userUID').set({
      'icon': status.icon,
      'status': status.status,
    });
  }

  Future<void> deleteStatus() async {
    var userUID = FirebaseAuth.instance.currentUser!.uid;
    await database.ref('users/$userUID').remove();
  }
}
