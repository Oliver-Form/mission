import 'package:flutter/material.dart';

class CleaningPage extends StatefulWidget {
  const CleaningPage({super.key});

  @override
  State<CleaningPage> createState() => _CleaningPageState();
}

class _CleaningPageState extends State<CleaningPage> {
  final List<Map<String, dynamic>> _rooms = [];
  final TextEditingController _roomController = TextEditingController();

  void _showAddRoomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Room'),
          content: TextField(
            controller: _roomController,
            decoration: const InputDecoration(
              hintText: 'Enter room name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _roomController.clear();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_roomController.text.isNotEmpty) {
                  setState(() {
                    _rooms.add({
                      'title': _roomController.text,
                    });
                  });
                  Navigator.of(context).pop();
                  _roomController.clear();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(room['title']),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    _rooms.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 