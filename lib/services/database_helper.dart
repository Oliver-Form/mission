import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MyLocationDatabaseHelper {
  static final MyLocationDatabaseHelper _instance =
      MyLocationDatabaseHelper._internal();

  factory MyLocationDatabaseHelper() {
    return _instance;
  }

  MyLocationDatabaseHelper._internal();

  static Database? _database;
  Future<Database?> get database async {
    _database = await initMyLocationDatabase();

    return _database;
  }

  Future<Database?> initMyLocationDatabase() async {
    final myUID = FirebaseAuth.instance.currentUser?.uid;
    if (myUID == null) {
      return null;
    }
    String path = join(
      await getDatabasesPath(),
      "my_locations_database_$myUID.db",
    );
    var db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE my_locations_table_$myUID(
            name TEXT,
            icon TEXT,
            latitude REAL,
            longitude REAL,
            radius INTEGER,
            PRIMARY KEY(name)
          )
        ''');
      },
    );
    return db;
  }

  Future<void> insertData(
    String name,
    String? icon,
    LatLng? coordinates,
    int? radius,
  ) async {
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    final Database? db = await database;

    final prevData = await getData(name);

    final _icon = icon ?? prevData!['icon'];
    final _coordinates =
        coordinates ?? LatLng(prevData!['latitude'], prevData['longitude']);
    final _radius = radius ?? prevData!['radius'];
    Map<String, dynamic> data = {
      'name': name,
      'icon': _icon,
      'latitude': _coordinates.latitude,
      'longitude': _coordinates.longitude,
      'radius': _radius,
    };

    await db!.insert(
      'my_locations_table_$myUID',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getData(String name) async {
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    final Database? db = await database;
    List<Map<String, dynamic>> maps = await db!.query(
      'my_locations_table_$myUID',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getAllData() async {
    final Database? db = await database;
    final myUID = FirebaseAuth.instance.currentUser?.uid;
    if (myUID == null) {
      return null;
    }
    final result = await db!.query('my_locations_table_$myUID');
    return result;
  }

  Future<int> deleteData(String name) async {
    final Database? db = await database;
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    return await db!.delete(
      'my_locations_table_$myUID',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<void> deleteAllData() async {
    final Database? db = await database;
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    db!.delete('my_locations_table_$myUID');
    db.execute('DROP TABLE my_locations_table_$myUID');
  }
}
class NotificationDatabaseHelper {
  static final NotificationDatabaseHelper _instance =
      NotificationDatabaseHelper._internal();

  factory NotificationDatabaseHelper() {
    return _instance;
  }

  NotificationDatabaseHelper._internal();

  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }
    _database = await initNotificationDatabase();

    return _database;
  }

  Future<Database> initNotificationDatabase() async {
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    String path = join(
      await getDatabasesPath(),
      "notification_database_$myUID.db",
    );
    var db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE notification_table_$myUID (
            timestamp TEXT,
            message TEXT,
            iconLink TEXT,
            PRIMARY KEY(timestamp)
          )
        ''');
      },
    );
    return db;
  }

  Future<void> insertData(
    String timestamp,
    String message,
    String iconLink,
  ) async {
    final Database? db = await database;
    final myUID = FirebaseAuth.instance.currentUser!.uid;

    Map<String, dynamic> data = {
      'timestamp': timestamp,
      'message': message,
      'iconLink': iconLink,
    };

    // Check if the data already exists
    await db!.insert(
      'notification_table_$myUID',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllData() async {
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    final Database? db = await database;
    return await db!.query('notification_table_$myUID');
  }
}
