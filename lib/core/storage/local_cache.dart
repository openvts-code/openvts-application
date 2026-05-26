import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  LocalCache(this._prefs);

  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  Future<bool> remove(String key) {
    return _prefs.remove(key);
  }
}
