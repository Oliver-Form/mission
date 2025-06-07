import 'package:flutter/material.dart';

class RoomDetailsPage extends StatefulWidget {
  final Map<String, dynamic> room;

  const RoomDetailsPage({
    super.key,
    required this.room,
  });

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  late double _progress;
  late Map<String, dynamic> _room;

  @override
  void initState() {
    super.initState();
    _room = Map<String, dynamic>.from(widget.room);
    _progress = _room['progress'] ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_room['title']),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cleaning Progress',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(_progress * 100).toInt()}% Clean',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                _progress >= 1.0 ? Icons.check_circle : Icons.cleaning_services,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: _progress,
                            onChanged: (value) {
                              setState(() {
                                _progress = value;
                                _room['progress'] = value;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Cleaning Tasks',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Placeholder for tasks list
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cleaning_services,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, _room);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
} 