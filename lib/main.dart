import 'package:flutter/material.dart';
import 'package:mission/screens/groceries_page.dart';
import 'package:mission/screens/overview_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:mission/screens/cleaning_page.dart';
import 'package:mission/services/user_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await UserPreferences.init();
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
  final TextEditingController _nameController = TextEditingController();

  static const List<IconData> _iconOptions = <IconData>[
    Icons.home,
    Icons.location_on,
    Icons.shopping_cart,
    Icons.cleaning_services,
  ];

  @override
  void initState() {
    super.initState();
    _checkName();
  }

  Future<void> _checkName() async {
    if (!UserPreferences.hasName()) {
      // Wait for the widget to be built
      await Future.delayed(Duration.zero);
      if (mounted) {
        _showNameDialog();
      }
    }
  }

  void _showNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome!'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await UserPreferences.setName(_nameController.text);
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? const OverviewPage()
          : _selectedIndex == 2
              ? const GroceriesPage()
              : _selectedIndex == 3
              ? const CleaningPage()
              : Column(
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Locations'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Groceries'),
          BottomNavigationBarItem(icon: Icon(Icons.cleaning_services), label: 'Cleaning'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// 