import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mission/providers/notification_provider.dart';
import 'package:mission/utilities/statics.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  static const String routeName = '/notification';
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  List notifications = [];

  @override
  void initState() {
    super.initState();
    ref.read(notificationProvider.notifier).loadNotification().then((_) {
      setState(() {
        notifications = ref.read(notificationProvider);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body:
          ref.watch(notificationProvider).isEmpty
              ? const Center(child: Text('No notifications available'))
              : ListView.builder(
                itemCount: ref.watch(notificationProvider).length,
                itemBuilder: (context, index) {
                  final notification = ref.watch(notificationProvider)[index];
                  final shortenTimestamp =
                      '${notification.timestamp.year}-${notification.timestamp.month.toString().padLeft(2, '0')}-${notification.timestamp.day.toString().padLeft(2, '0')} ${notification.timestamp.hour.toString().padLeft(2, '0')}:${notification.timestamp.minute.toString().padLeft(2, '0')}';

                  if (notification.type == 'Friend Request') {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0,
                      ),
                      title: Text(notification.body),
                      subtitle: Text(shortenTimestamp),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(notification.iconLink),
                      ),
                    );
                  }
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                    title: Text(notification.body),
                    subtitle: Text(shortenTimestamp),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          (notification.iconLink.isNotEmpty)
                              ? NetworkImage(notification.iconLink)
                              : NetworkImage(Statics.defaultIconLink),
                    ),
                  );
                },
              ),
    );
  }
}
