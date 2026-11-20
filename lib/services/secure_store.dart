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
  static const String keyVaultKey = 'vk_vault_key';
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

/// Convenience accessors for the settings VaultKey stores securely.
extension SecureStoreSettings on SecureStore {
  Future<bool> get isSetupDone async =>
      (await read(SecureStore.keySetupDone)) == 'true';

  Future<void> setSetupDone(bool value) =>
      write(SecureStore.keySetupDone, value ? 'true' : 'false');

  Future<bool> get isBiometricEnabled async =>
      (await read(SecureStore.keyBiometricEnabled)) == 'true';

  Future<void> setBiometricEnabled(bool value) =>
      write(SecureStore.keyBiometricEnabled, value ? 'true' : 'false');

  /// Auto-lock delay in minutes. Defaults to 2 when unset.
  Future<int> get autoLockMinutes async {
    final raw = await read(SecureStore.keyAutoLockMinutes);
    final parsed = int.tryParse(raw ?? '');
    if (parsed == null || parsed <= 0) return 2;
    return parsed;
  }

  Future<void> setAutoLockMinutes(int minutes) =>
      write(SecureStore.keyAutoLockMinutes, minutes.toString());

  Future<int> get failedAttempts async {
    final raw = await read(SecureStore.keyFailedAttempts);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> setFailedAttempts(int value) =>
      write(SecureStore.keyFailedAttempts, value.toString());

  Future<DateTime?> get lockoutUntil async {
    final raw = await read(SecureStore.keyLockoutUntil);
    if (raw == null || raw.isEmpty) return null;
    final millis = int.tryParse(raw);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLockoutUntil(DateTime? value) async {
    if (value == null) {
      await delete(SecureStore.keyLockoutUntil);
    } else {
      await write(
        SecureStore.keyLockoutUntil,
        value.millisecondsSinceEpoch.toString(),
      );
    }
  }
}
