import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyServerUrl = 'server_url';
  static const String keyDbName = 'db_name';
  static const String keyUsername = 'username';
  static const String keyPassword = 'password'; // Note: In prod, store securely (flutter_secure_storage)
  static const String keyEmployeeId = 'employee_id';

  Future<void> saveCredentials(String url, String db, String user, String password, int employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyServerUrl, url);
    await prefs.setString(keyDbName, db);
    await prefs.setString(keyUsername, user);
    await prefs.setString(keyPassword, password);
    await prefs.setInt(keyEmployeeId, employeeId);
  }

  Future<Map<String, dynamic>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'url': prefs.getString(keyServerUrl),
      'db': prefs.getString(keyDbName),
      'user': prefs.getString(keyUsername),
      'password': prefs.getString(keyPassword),
      'employeeId': prefs.getInt(keyEmployeeId),
    };
  }

  Future<bool> hasCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(keyServerUrl) && prefs.containsKey(keyEmployeeId);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyServerUrl);
    await prefs.remove(keyDbName);
    await prefs.remove(keyUsername);
    await prefs.remove(keyPassword);
    await prefs.remove(keyEmployeeId);
  }
}
