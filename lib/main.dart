import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mission/providers/friend_location_provider.dart';
import 'package:mission/providers/profile_provider.dart';
import 'package:mission/screens/groceries_page.dart';
import 'package:mission/screens/location_screen.dart';
import 'package:mission/screens/overview_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mission/screens/authGate.dart';
import 'package:mission/screens/profile_setting_screen.dart';
import 'firebase_options.dart';
import 'package:mission/screens/cleaning_page.dart';
import 'package:mission/services/user_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await UserPreferences.init();
   await dotenv.load(fileName: "lib/credential.env");
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool isLoggedIn = false;
  ThemeMode mode = ThemeMode.system; // Define the mode variable

  @override
  void initState() {
    super.initState();
    ref.read(profileProvider.notifier).loadMyProfile();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        isLoggedIn = user != null;
      });
      ref.read(friendProfilesProvider.notifier).loadFriendProfiles();
      ref.read(friendLocationProvider.notifier).loadFriendLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA97C73)),
      ),
      home: isLoggedIn? MyHomePage(): AuthGate(),
      routes:{
        MyHomePage.routeName: (context) => const MyHomePage(),
        AuthGate.routeName: (context) => const AuthGate(),
        ProfileSettingScreen.routeName: (context) => const ProfileSettingScreen(),
      }
    );
  }
}

class MyHomePage extends StatefulWidget {
  static const routeName = 'home';
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final TextEditingController _nameController = TextEditingController();


  @override
  void initState() {
    super.initState();
    
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

 List<Widget> screens =
     [
      const OverviewPage(),
       LocationScreen(),
      GroceriesPage(),
      const CleaningPage(),
    ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_selectedIndex],
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