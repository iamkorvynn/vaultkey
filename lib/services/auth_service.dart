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
/// * Biometric: [authenticateBiometric] asks the OS; it only works after a
///   master password exists, and the vault key itself is re-derived from a
///   cached in-memory copy — the key is never persisted to disk.
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
    _crypto = CryptoService(key);
    return null;
  }
