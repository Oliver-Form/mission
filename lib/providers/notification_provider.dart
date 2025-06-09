import 'package:mission/utilities/firestore_helper.dart';
import 'package:mission/utilities/prefs_helper.dart';
import 'package:mission/utilities/statics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Notification {
  final String body;
  final String iconLink;
  final DateTime timestamp;
  final String type;
  final String senderUID;
  final String? message;
  Notification(
    this.body,
    this.iconLink,
    this.timestamp,
    this.type,
    this.senderUID, {
    this.message,
  });
}

@riverpod
class NotificationProvider extends Notifier<List<Notification>> {
  @override
  List<Notification> build() => [];

  Future<void> loadNotification() async {
    final notifications = await FirestoreHelper().getNotifications();
      List<Notification> result = [];
      for (var element in notifications) {
        var datetime = element['timestamp'].toDate();
        var type = element['type'] ?? 'General';
        result.add(
          Notification(
            element['body'],
            element['imageUrl'] ?? Statics.defaultIconLink,
            datetime,
            type,
            element['senderUID'],
            message: element['message'],
          ),
        );
      }
      state = result;
  }

  
}

final notificationProvider =
    NotifierProvider<NotificationProvider, List<Notification>>(
      NotificationProvider.new,
    );

@riverpod
class UnreadNotificationProvider extends Notifier<int> {
    @override
  int build() {
    return 0;
  }

  Future<void> loadUnreadNotificationCount() async {
      int readCount = await PrefsHelper().getReadNotification();
      int totalCount = ref.read(notificationProvider).length; //here changing to ref.read() made the provider work
      state = totalCount - readCount;
  }
  void resetUnreadNotificationCount() {
    state = 0;
  }
}

final unreadNotificationProvider =
    NotifierProvider<UnreadNotificationProvider, int>(
      UnreadNotificationProvider.new,
    );
