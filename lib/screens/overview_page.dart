import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mission/providers/profile_provider.dart';
import 'package:mission/screens/profile_setting_screen.dart';
import 'package:mission/services/statics.dart';
import 'package:mission/services/user_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({Key? key}) : super(key: key);

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  bool _dishesDone = false;
  final _doc = FirebaseFirestore.instance
      .collection('overview')
      .doc('sharedOverviewChecklist');

  @override
  void initState() {
    super.initState();
    // Load initial state and listen for external changes
    _doc.snapshots().listen((snap) {
      if (snap.exists) {
        setState(() {
          _dishesDone = (snap.data()?['dishesDone'] as bool?) ?? false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(profileProvider).name ?? 'User';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            icon: (ref.watch(profileProvider).iconLink != null)
                ? CircleAvatar(
                    backgroundImage: NetworkImage(ref.watch(profileProvider).iconLink?? Statics.defaultIconLink),
                  )
                : const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(context).pushNamed(ProfileSettingScreen.routeName, arguments: {
                'isNewUser': false,
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi $userName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Dishes Done'),
                    value: _dishesDone,
                    onChanged: (val) {
                      final newValue = val ?? false;
                      // update Firestore
                      _doc.update({'dishesDone': newValue});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
