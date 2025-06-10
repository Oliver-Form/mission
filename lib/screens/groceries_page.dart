import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mission/providers/profile_provider.dart';

class GroceriesPage extends ConsumerStatefulWidget {
  const GroceriesPage({Key? key}) : super(key: key);

  @override
  ConsumerState<GroceriesPage> createState() => _GroceriesPageState();
}

class _GroceryItem {
  String name;
  bool done;
  _GroceryItem(this.name) : done = false;
}

class _GroceriesPageState extends ConsumerState<GroceriesPage> {
  // Firestore collection reference
  final _groceries = FirebaseFirestore.instance.collection('groceries');
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addItem(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    
    final userName = ref.watch(profileProvider).name ?? 'Unknown';
    await _groceries.add({
      'name': trimmed,
      'done': false,
      'user': userName,
    });
    _controller.clear();
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Grocery Item'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter item name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (_) => _addFromDialog(ctx),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _controller.clear();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _addFromDialog(ctx),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addFromDialog(BuildContext ctx) async {
    await _addItem(_controller.text);
    Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _groceries.orderBy('name').snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) return const Center(child: Text('Error loading items'));
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data()! as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Checkbox(
                    value: data['done'] as bool? ?? false,
                    onChanged: (checked) {
                      doc.reference.update({'done': checked});
                    },
                  ),
                  title: Text(data['name'] ?? ''),
                  subtitle: Text('Added by ${data['user'] ?? 'Unknown'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await doc.reference.delete();
                    },
                  ),
                  onTap: () {
                    final newValue = !(data['done'] as bool? ?? false);
                    doc.reference.update({'done': newValue});
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

