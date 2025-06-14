import 'package:flutter/material.dart';
import 'package:mission/providers/profile_provider.dart';
import 'package:mission/screens/room_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mission/services/user_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CleaningPage extends ConsumerStatefulWidget {
  const CleaningPage({super.key});

  @override
  ConsumerState<CleaningPage> createState() => _CleaningPageState();
}

class _CleaningPageState extends ConsumerState<CleaningPage> {
  final TextEditingController _roomController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _assignUnassignedRooms() async {
    final roomsSnapshot = await _firestore.collection('rooms').get();
    final rooms = roomsSnapshot.docs;

    for (var room in rooms) {
      final roomData = room.data();
      if (roomData['assignedUser'] == null) {
        final assignedUser = await _getAssignedUser();
        await room.reference.update({'assignedUser': assignedUser});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _assignUnassignedRooms();
  }

  Future<String> _getAssignedUser() async {
    final userName = ref.read(profileProvider).name ?? 'Unknown';
    
    // Get all users and their room counts
    final usersSnapshot = await _firestore.collection('user').get();
    final users = usersSnapshot.docs;
    
    // If user doesn't exist in users collection, add them
    if (!users.any((doc) => doc.data()['name'] == userName)) {
      await _firestore.collection('user').add({
        'name': userName,
        'roomCount': 0,
      });
    }

    // Get all rooms and their assigned users
    final roomsSnapshot = await _firestore.collection('rooms').get();
    final rooms = roomsSnapshot.docs;
    
    // Count rooms per user
    final userRoomCounts = <String, int>{};
    for (var room in rooms) {
      final assignedUser = room.data()['assignedUser'] as String?;
      if (assignedUser != null) {
        userRoomCounts[assignedUser] = (userRoomCounts[assignedUser] ?? 0) + 1;
      }
    }

    // Find user with least rooms
    String? assignedUser;
    int minRooms = -1;
    
    for (var user in users) {
      final userData = user.data();
      final userDisplayName = userData['name'] as String? ?? 'Unknown';
      final roomCount = userRoomCounts[userDisplayName] ?? 0;
      if (minRooms == -1 || roomCount < minRooms) {
        minRooms = roomCount;
        assignedUser = userDisplayName;
      }
    }

    return assignedUser ?? userName;
  }

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
                    final assignedUser = await _getAssignedUser();
                    await _firestore.collection('rooms').add({
                      'title': _roomController.text,
                      'progress': 0.0,
                      'comments': <Map<String, dynamic>>[],
                      'assignedUser': assignedUser,
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
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
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
                      const SizedBox(height: 4),
                      Text(
                        'Assigned to: ${room['assignedUser'] ?? 'Unassigned'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
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