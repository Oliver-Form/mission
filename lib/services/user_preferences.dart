import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _nameKey = 'user_name';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setName(String name) async {
    await _prefs?.setString(_nameKey, name);
  }

  static String? getName() {
    return _prefs?.getString(_nameKey);
  }

  static bool hasName() {
    return _prefs?.containsKey(_nameKey) ?? false;
  }
}
