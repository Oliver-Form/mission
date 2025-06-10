import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsernameNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setUsername(String username) {
    state = username;
  }

  void clearUsername() {
    state = '';
  }
}

final usernameProvider = NotifierProvider<UsernameNotifier, String>(
  UsernameNotifier.new,
);