import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mission/providers/friend_location_provider.dart';
import 'package:mission/providers/my_status_provider.dart';

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

  Future<void> updateStatus(UserStatus status) async {
    var userUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _firestore.collection('status').doc(userUID).update({
        'status': status.status,
        'icon': status.icon, // Default icon, can be changed later
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<UserStatus> getStatus(String friendUID) async {
    try {
      final statusDoc = await _firestore
          .collection('status')
          .doc(friendUID)
          .get();
      if (statusDoc.exists) {
        var data = statusDoc.data();
        return UserStatus(
          data?['status'] ?? 'Available',
          data?['icon'] ?? 'default_icon.png',
        );
      } else {
        return UserStatus('Offline', '🔴');
      }
    } catch (e) {
      print('Error getting status: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(LatLng coordinates) async {
    var myUID = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _firestore.collection('locations').doc(myUID).set({
        'coordinates': GeoPoint(coordinates.latitude, coordinates.longitude),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }
  Stream<QuerySnapshot> getFriendLocationsStream(String myUID) {
    return _firestore.collection('locations').snapshots();
  }

  Future<Map<String, Location>> getAllFriendLocations() async {
    try {
      final locationsSnapshot = await _firestore.collection('locations').get();
      final friendLocationMap = locationsSnapshot.docs.asMap().map((
        index,
        doc,
      ) {
        var data = doc.data();
        GeoPoint geoPoint = data['coordinates'];
        return MapEntry(
          doc.id,
          Location(
            latlng: LatLng(geoPoint.latitude, geoPoint.longitude),
            timestamp: data['timestamp'],
          ),
        );
      });
      return friendLocationMap;
    } catch (e) {
      print('Error getting friend locations: $e');
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
      final userDoc = await _firestore
          .collection('userProfiles')
          .doc(userUID)
          .get();

      return userDoc.data() ?? {};
    } catch (e) {
      print('Error getting documents: $e');
      rethrow;
    }
  }

  Future<String> getUIDFromUsername(String username) async {
    try {
      final querySnapshot = await _firestore
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

  Future<LatLng?> getEmergencyLocation(String friendUID) async {
    final emergencyDoc = await _firestore
        .collection('emergency')
        .doc(friendUID)
        .get();
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

  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      final profilesSnapshot = await _firestore
          .collection('userProfiles')
          .get();
      return profilesSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting all profiles: $e');
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
      final passwordDoc = await _firestore
          .collection('userPasswords')
          .doc(userUID)
          .get();
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
      final addressDoc = await _firestore
          .collection('userPasswords')
          .doc(userUID)
          .get();
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
    if (oldFriendList.isEmpty) {}
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
      final friendListDoc = await _firestore
          .collection('friendList')
          .doc(myUID)
          .get();
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
    final querySnapshot = await _firestore.collection('userProfiles').get();
    final profilesList = Map.fromEntries(
      querySnapshot.docs.map(
      (doc) => MapEntry(doc.id, doc.data()),
      ),
    );
    return profilesList;
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

  Future<void> addMessage({
    required String title,
    required String body,
    required String imageUrl,
    required String type,
    required List<String> receivers,
    String? message,
  }) async {
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
      await addNotification(
        title,
        body,
        imageUrl,
        type,
        receivers,
        senderUID,
        message: message,
      );
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
    String senderUID, {
    String? message,
  }) async {
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
      final notificationDoc = await _firestore
          .collection('notifications')
          .doc(myUID)
          .get();
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
