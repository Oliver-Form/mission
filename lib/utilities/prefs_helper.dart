import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  //arrival notification list
  Future<void> addNotificationPrefs(String friendUID) async {
    final prefs = await SharedPreferences.getInstance();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    List<String> notificationList = await getNotificationPrefs();
    notificationList.add(friendUID);
    await prefs.setStringList('notificationList_$myUID', notificationList);
  }

  Future<void> removeNotificationPrefs(String friendUID) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationList = await getNotificationPrefs();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    notificationList.remove(friendUID);
    await prefs.setStringList('notificationList_$myUID', notificationList);
  }

  Future<List<String>> getNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    List<String> notificationList =
        prefs.getStringList('notificationList_$myUID') ?? [];
    return notificationList;
  }

  ////emergency notification list
  Future<void> addEmergencyPrefs(String friendUID) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> emergencyList = await getEmergencyPrefs();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    emergencyList.add(friendUID);
    await prefs.setStringList('emergencyList_$myUID', emergencyList);
  }

  Future<List<String>> getEmergencyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    List<String> emergencyList =
        prefs.getStringList('emergencyList_$myUID') ?? [];
    return emergencyList;
  }

  Future<void> removeEmergencyPrefs(String friendUID) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> emergencyList = await getEmergencyPrefs();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    emergencyList.remove(friendUID);
    await prefs.setStringList('emergencyList_$myUID', emergencyList);
  }

  Future<void> addLocationNotificationPrefs(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    List<String> locationNotificationList =
        await getLocationNotificationPrefs();
    locationNotificationList.add(status);
    await prefs.setStringList(
      'locationNotificationList_$myUID',
      locationNotificationList,
    );
  }

  //registered location
  Future<List<String>> getLocationNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    List<String> locationNotificationList =
        prefs.getStringList('locationNotificationList_$myUID') ?? [];
    return locationNotificationList;
  }

  Future<void> removeLocationNotificationPrefs(String status) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> locationNotificationList =
        await getLocationNotificationPrefs();
    if (locationNotificationList.contains(status)) {
      final myUID = FirebaseAuth.instance.currentUser!.uid;
      locationNotificationList.remove(status);
      await prefs.setStringList(
        'locationNotificationList_$myUID',
        locationNotificationList,
      );
    }
  }

  // mute list
  Future<void> addMutePrefs(String friendUID) async {
    final prefs = await SharedPreferences.getInstance();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    List<String> muteList = await getMutePrefs();
    muteList.add(friendUID);
    await prefs.setStringList('muteList_$myUID', muteList);
  }

  Future<List<String>> getMutePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    List<String> muteList = prefs.getStringList('muteList_$myUID') ?? [];
    return muteList;
  }

  Future<void> removeMutePrefs(String friendUID) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> muteList = await getMutePrefs();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    muteList.remove(friendUID);
    await prefs.setStringList('muteList_$myUID', muteList);
  }

  // unread notification
  Future<void> updateReadNotificationPrefs(int length) async {
    final prefs = await SharedPreferences.getInstance();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    await prefs.setInt('unreadNotification_$myUID', length);
  }

  Future<int> getReadNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final myUID = FirebaseAuth.instance.currentUser!.uid;
    int length = prefs.getInt('unreadNotification_$myUID') ?? 0;
    return length;
  }
}
