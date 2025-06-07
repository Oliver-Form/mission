import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA97C73)),
      ),
      home: const MyHomePage(title: 'My run app!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<IconData> _iconOptions = <IconData>[
    Icons.location_on,
    Icons.shopping_cart,
    Icons.cleaning_services,
    Icons.emoji_food_beverage,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 64, 0, 8),
            child: Text(
              'Mission',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ), 
          ),
          Expanded(
            child: Center(
              child: Icon(
                _iconOptions[_selectedIndex],
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Locations'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Groceries'),
          BottomNavigationBarItem(icon: Icon(Icons.cleaning_services), label: 'Cleaning'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_food_beverage), label: 'Dishes'), // Plate-like icon
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

