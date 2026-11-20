import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tiny typed wrapper around the platform secure enclave
/// (Keystore on Android, Keychain on iOS).
///
/// Only non-secret settings and key material live here — never a password
/// and never a vault entry. Everything is stored under the `vk_` prefix.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const String keySalt = 'vk_salt';
  static const String keyMasterVerifier = 'vk_master_verifier';
  static const String keySetupDone = 'vk_setup_done';
  static const String keyBiometricEnabled = 'vk_biometric_enabled';
  static const String keyAutoLockMinutes = 'vk_autolock_minutes';
  static const String keyFailedAttempts = 'vk_failed_attempts';
  static const String keyLockoutUntil = 'vk_lockout_until';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  /// Wipes every VaultKey key from secure storage (used by "erase vault").
  Future<void> deleteAll() => _storage.deleteAll();
}
