import 'package:flutter/material.dart';
import 'package:mission/screens/room_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CleaningPage extends StatefulWidget {
  const CleaningPage({super.key});

  @override
  State<CleaningPage> createState() => _CleaningPageState();
}

class _CleaningPageState extends State<CleaningPage> {
  final TextEditingController _roomController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
              onPressed: () async {
                if (_roomController.text.isNotEmpty) {
                  try {
                    await _firestore.collection('rooms').add({
                      'title': _roomController.text,
                      'progress': 0.0,
                      'comments': <Map<String, dynamic>>[],
                    });
                    Navigator.of(context).pop();
                    _roomController.clear();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding room: $e')),
                    );
                  }
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index].data() as Map<String, dynamic>;
              final roomId = rooms[index].id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(room['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: room['progress'] ?? 0.0,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((room['progress'] ?? 0.0) * 100).toInt()}% Clean',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      try {
                        await _firestore.collection('rooms').doc(roomId).delete();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting room: $e')),
                        );
                      }
                    },
                  ),
                  onTap: () async {
                    final updatedRoom = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomDetailsPage(
                          room: room,
                          roomId: roomId,
                        ),
                      ),
                    );
                    if (updatedRoom != null) {
                      try {
                        await _firestore.collection('rooms').doc(roomId).update(updatedRoom);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating room: $e')),
                        );
                      }
                    }
                  },
                ),
              );
            },
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