import 'dart:convert';

import 'package:local_auth/local_auth.dart';

import 'crypto_service.dart';
import 'secure_store.dart';

/// Owns the master-password lifecycle and biometric unlock.
///
/// Flow:
/// * First run: [setupMasterPassword] creates a fresh salt, derives the
///   vault key, stores the verifier hash and marks setup done.
/// * Unlock: [verifyMasterPassword] re-derives the key and compares the
///   verifier in constant time. On success it returns the [CryptoService]
///   the vault needs; on failure it counts attempts and locks out after
///   [maxFailedAttempts].
/// * Biometric: the derived vault key is kept in the OS-encrypted
///   keystore (via flutter_secure_storage) so biometric unlock works
///   across restarts. [unlockWithBiometrics] only reads that key after
///   the OS biometric prompt succeeds; the key is never stored in plain
///   SQLite and never leaves the device.
class AuthService {
  AuthService({
    SecureStore? store,
    LocalAuthentication? localAuth,
  })  : _store = store ?? SecureStore(),
        _localAuth = localAuth ?? LocalAuthentication();

  final SecureStore _store;
  final LocalAuthentication _localAuth;

  /// Failed attempts before a temporary lockout kicks in.
  static const int maxFailedAttempts = 5;

  /// Lockout length after [maxFailedAttempts] failures.
  static const Duration lockoutDuration = Duration(minutes: 1);

  /// Minimum master password length enforced at setup.
  static const int minPasswordLength = 8;

  /// The in-memory vault key, set only while the vault is unlocked.
  /// Cleared on lock. Never written to disk.
  CryptoService? _crypto;

  CryptoService? get crypto => _crypto;

  bool get isUnlocked => _crypto != null;

  Future<bool> get isSetupDone => _store.isSetupDone;

  /// Creates the vault's master password. Returns an error string, or null
  /// on success.
  Future<String?> setupMasterPassword(String password) async {
    if (password.length < minPasswordLength) {
      return 'Master password must be at least $minPasswordLength characters.';
    }
    final salt = CryptoService.generateSalt();
    final key = CryptoService.deriveKey(password, salt);
    await _store.write(SecureStore.keySalt, salt);
    await _store.write(
      SecureStore.keyMasterVerifier,
      masterPasswordVerifier(key),
    );
    await _store.setSetupDone(true);
    await _store.setFailedAttempts(0);
    await _store.setLockoutUntil(null);
    await _store.write(
      SecureStore.keyVaultKey,
      base64Encode(key),
    );
    _crypto = CryptoService(key);
    return null;
  }

  /// Verifies [password] against the stored verifier.
  /// Returns the [CryptoService] on success, null on failure.
  /// Counts failures and enforces the lockout window.
  Future<CryptoService?> verifyMasterPassword(String password) async {
    final lockoutUntil = await _store.lockoutUntil;
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      return null;
    }
    final salt = await _store.read(SecureStore.keySalt);
    final verifier = await _store.read(SecureStore.keyMasterVerifier);
    if (salt == null || verifier == null) return null;
    final key = CryptoService.deriveKey(password, salt);
    if (!_constantTimeEquals(masterPasswordVerifier(key), verifier)) {
      final attempts = await _store.failedAttempts + 1;
      await _store.setFailedAttempts(attempts);
      if (attempts >= maxFailedAttempts) {
        await _store.setLockoutUntil(DateTime.now().add(lockoutDuration));
        await _store.setFailedAttempts(0);
      }
      return null;
    }
    await _store.setFailedAttempts(0);
    await _store.setLockoutUntil(null);
    await _store.write(
      SecureStore.keyVaultKey,
      base64Encode(key),
    );
    _crypto = CryptoService(key);
    return _crypto;
  }

  /// Compares two strings without leaking timing information.
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Remaining lockout time, or null when not locked out.
  Future<Duration?> lockoutRemaining() async {
    final until = await _store.lockoutUntil;
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    if (remaining.isNegative) {
      await _store.setLockoutUntil(null);
      return null;
    }
    return remaining;
  }

  /// Number of consecutive failed attempts in the current window.
  Future<int> get failedAttempts => _store.failedAttempts;

  /// Attempts left before the lockout triggers.
  Future<int> get attemptsLeft async {
    final attempts = await failedAttempts;
    final left = maxFailedAttempts - attempts;
    return left < 0 ? 0 : left;
  }

  /// Whether the device can do biometric auth at all.
  Future<bool> get canUseBiometrics async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Whether the user enabled biometric unlock in settings.
  Future<bool> get isBiometricEnabled => _store.isBiometricEnabled;

  Future<void> setBiometricEnabled(bool value) =>
      _store.setBiometricEnabled(value);

  /// Unlocks the vault with biometrics: runs the OS prompt, then reads
  /// the vault key from the OS keystore. Returns the [CryptoService] on
  /// success, null when biometrics are off, unavailable, or fail.
  Future<CryptoService?> unlockWithBiometrics() async {
    final enabled = await isBiometricEnabled;
    if (!enabled) return null;
    final ok = await authenticateBiometric();
    if (!ok) return null;
    final stored = await _store.read(SecureStore.keyVaultKey);
    if (stored == null || stored.isEmpty) return null;
    try {
      final key = base64Decode(stored);
      _crypto = CryptoService(key);
      return _crypto;
    } catch (_) {
      return null;
    }
  }

  /// Runs the OS biometric prompt. Returns true when the user authenticated.
  Future<bool> authenticateBiometric() async {
    try {
      final available = await canUseBiometrics;
      if (!available) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Unlock VaultKey with biometrics',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Changes the master password. Re-encrypts nothing in the database:
  /// entries are re-encrypted by the caller-provided [reencrypt] callback,
  /// which must rewrite every entry under the new key. Returns an error
  /// string, or null on success.
  Future<String?> changeMasterPassword(
    String currentPassword,
    String newPassword,
    Future<void> Function(CryptoService oldCrypto, CryptoService newCrypto)
        reencrypt,
  ) async {
    if (newPassword.length < minPasswordLength) {
      return 'New password must be at least $minPasswordLength characters.';
    }
    final oldCrypto = await verifyMasterPassword(currentPassword);
    if (oldCrypto == null) return 'Current password is incorrect.';
    final salt = CryptoService.generateSalt();
    final newKey = CryptoService.deriveKey(newPassword, salt);
    final newCrypto = CryptoService(newKey);
    await reencrypt(oldCrypto, newCrypto);
    await _store.write(SecureStore.keySalt, salt);
    await _store.write(
      SecureStore.keyMasterVerifier,
      masterPasswordVerifier(newKey),
    );
    await _store.write(
      SecureStore.keyVaultKey,
      base64Encode(newKey),
    );
    _crypto = newCrypto;
    return null;
  }

  /// Locks the vault: drops the in-memory key.
  void lock() {
    _crypto = null;
  }
}
