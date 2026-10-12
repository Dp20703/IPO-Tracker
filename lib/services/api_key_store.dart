import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the user's personal IPO Guru API key using the device's secure
/// storage (Android Keystore backed). The key never leaves the device
/// except in the "X-API-KEY" header of a request the user initiates.
class ApiKeyStore {
  static const _storage = FlutterSecureStorage();
  static const _ipoGuruKeyName = 'ipoguru_api_key';

  static Future<String?> getIpoGuruKey() async {
    try {
      return await _storage.read(key: _ipoGuruKeyName);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setIpoGuruKey(String key) async {
    await _storage.write(key: _ipoGuruKeyName, value: key.trim());
  }

  static Future<void> clearIpoGuruKey() async {
    await _storage.delete(key: _ipoGuruKeyName);
  }
}
