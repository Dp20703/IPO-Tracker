import 'package:shared_preferences/shared_preferences.dart';

/// The shared IPO list URL is a public link (e.g. a Google Sheet published
/// to the web as CSV), not a secret — so plain SharedPreferences is fine
/// here, unlike the IPO Guru API key which uses secure storage.
class SharedListSettings {
  static const _urlKey = 'shared_ipo_list_url';

  static Future<String?> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey);
  }

  static Future<void> setUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url.trim());
  }

  static Future<void> clearUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
  }
}
