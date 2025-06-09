import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mission/utilities/firestore_helper.dart';

@riverpod
class FriendListProvider extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  //keep user's basic profile
  Future<void> loadFriendList() async {
    var friendList = await FirestoreHelper().getFriendList();
    state = friendList;
  }
}

final friendListProvider = NotifierProvider<FriendListProvider, List<String>>(
  FriendListProvider.new,
);
