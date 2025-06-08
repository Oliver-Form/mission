import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mission/services/user_preferences.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({Key? key}) : super(key: key);

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
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
    final userName = UserPreferences.getName() ?? 'Guest';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // TODO: handle account action
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
