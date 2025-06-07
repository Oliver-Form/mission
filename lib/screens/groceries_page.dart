import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroceriesPage extends StatefulWidget {
  const GroceriesPage({Key? key}) : super(key: key);

  @override
  State<GroceriesPage> createState() => _GroceriesPageState();
}

class _GroceryItem {
  String name;
  bool done;
  _GroceryItem(this.name) : done = false;
}

class _GroceriesPageState extends State<GroceriesPage> {
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
    await _groceries.add({
      'name': trimmed,
      'done': false,
      'user': 'bob',
      // timestamp can be added later if needed
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
      child: Column(
        children: [
          // input field with outlined border and integrated add button
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Add Grocery Item',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addItem(_controller.text),
              ),
            ),
            onSubmitted: _addItem,
          ),
          const SizedBox(height: 16),
          // Real-time list from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _groceries.orderBy('name').snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError) return const Center(child: Text('Error loading items'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    return CheckboxListTile(
                      title: Text(data['name'] ?? ''),
                      value: data['done'] as bool? ?? false,
                      onChanged: (checked) {
                        doc.reference.update({'done': checked});
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

