import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mission/services/firestore_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

@riverpod
class MemberListProvider extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  //keep user's basic profile
  Future<void> loadMemberList() async {
    final myUID = FirebaseAuth.instance.currentUser?.uid;

    //get user data from firebase
    var profile = await FirestoreHelper().getAllProfiles();
    //save to riverpod
    state = profile.map((p) => p['userUID'] as String).toList();
  }

  void resetProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    state = [];
  }
}

final memberListProvider = NotifierProvider<MemberListProvider, List<String>>(
  MemberListProvider.new,
);