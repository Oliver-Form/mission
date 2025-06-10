import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mission/providers/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mission/services/firestore_helper.dart';
import 'package:mission/services/statics.dart';
import 'package:mission/providers/friend_list_provider.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  List friendList = [];
  List profileList = [Profile];
  String userState = 'offline';
  late StreamSubscription friendsSubscription;
  late StreamSubscription statusSubscription;
  late StreamSubscription notificationSubscription;
  Map statusMap = {};
  bool isLoading = true;
  bool isUnreadLoading = true;

  String? imagePath;

  Map locationAvailableMap = {};

  Future<void> updatePrefs(var snapshot) async {
    await ref.read(memberListProvider.notifier).loadMemberList();
    final newFriendUID = snapshot.data()!['friendList'].last;
    updateFriendStatus(newFriendUID);
  }

  Future<void> updateFriendStatus(String friendUID) async {
    final map =
        await FirestoreHelper().getStatus(friendUID); // Get status from Firestore
    if (map != null) {
      setState(() {
        statusMap[friendUID] = map;
      });
    } // Update home widget with first friend
  }

  Future<void> updateLocationAvailable(String friendUID) async {
    final location = await FirestoreHelper().getEmergencyLocation(friendUID);
    setState(() {
      locationAvailableMap[friendUID] = location != null;
    });
  }

  @override
  void initState() {
    super.initState();
    final myUID = FirebaseAuth.instance.currentUser?.uid;

    statusSubscription = FirebaseFirestore.instance
      .collection('status')
      .snapshots()
      .listen((snapshot) {
        // Clear previous status
        for (var doc in snapshot.docs) {
        final friendUID = doc.id;
        final data = doc.data();
        setState(() {
          statusMap[friendUID] = data;
        });
        }
      });

    friendsSubscription = FirebaseFirestore.instance
        .collection('friendList')
        .doc(myUID)
        .snapshots()
        .listen((snapshot) {
          ref.read(friendProfilesProvider.notifier).loadFriendProfiles();
          ref.read(memberListProvider.notifier).loadMemberList();
          if (snapshot.exists) {
            updatePrefs(snapshot);
          }
        });
  }


  @override
  void dispose() {
    statusSubscription.cancel();
    friendsSubscription.cancel();
    super.dispose();
  }

  Widget buildFriendCard(String friendUID) {
    final profile = ref.watch(friendProfilesProvider)[friendUID];
    bool isEmergency = statusMap[friendUID]?['status'] == 'feeling unsafe';
    bool isLocationLoading = true;
    if (isEmergency) {
      updateLocationAvailable(friendUID);
      isLocationLoading = locationAvailableMap[friendUID] == null;
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      elevation: 3.0,
      color: isEmergency ? Colors.red : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    profile?.iconLink ??
                        Statics.defaultIconLink, // default icon link
                  ),
                ), // a cat image
                SizedBox(height: 20),
                Text(
                  overflow: TextOverflow.ellipsis,
                  profile?.name ?? 'Username',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  profile?.bio ?? 'Bio',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 60),

                //status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      isLoading
                          ? Center(child: CircularProgressIndicator())
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                statusMap[friendUID]?['icon'] ?? '🔴',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 160,
                                  minWidth: 50,
                                ),
                                child: Text(
                                  statusMap[friendUID]?['status'] ?? 'offline',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    friendList = ref.watch(
      memberListProvider
    ); // Update home widget with first friend
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        automaticallyImplyLeading: false,
      ),
      body:
          friendList.isEmpty
              ? Center(child: Text("Let's add friends by pressing + button"))
              : PageView.builder(
                physics: const BouncingScrollPhysics(),
                controller: PageController(viewportFraction: 0.8),
                itemCount: friendList.length,
                itemBuilder: (context, index) {
                  final friendUID = friendList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 40,
                    ),
                    child: buildFriendCard(friendUID),
                  );
                },
              ),
    );
  }
}
