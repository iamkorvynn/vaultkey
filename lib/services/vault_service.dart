import '../models/vault_entry.dart';
import 'auth_service.dart';
import 'crypto_service.dart';
import 'vault_repository.dart';

/// Orchestrates the vault: holds the [AuthService] and the unlocked
/// [VaultRepository], and knows how to re-encrypt every entry when the
/// master password changes.
///
/// The repository is rebuilt on every unlock because it is bound to the
/// current [CryptoService]; the underlying SQLite file is shared.
class VaultService {
  VaultService({AuthService? auth}) : _auth = auth ?? AuthService();

  final AuthService _auth;

  AuthService get auth => _auth;

  VaultRepository? _repository;

  VaultRepository get repository {
    final crypto = _auth.crypto;
    final repo = _repository;
    if (crypto == null || repo == null) {
      throw StateError('Vault is locked — unlock first.');
    }
    return repo;
  }

  bool get isUnlocked => _auth.isUnlocked;

  /// Binds a fresh repository to the current unlock session.
  void bindRepository() {
    final crypto = _auth.crypto;
    if (crypto == null) {
      throw StateError('Cannot bind repository while locked.');
    }
    _repository = VaultRepository(crypto: crypto);
  }

  /// Locks the vault: drops the key and the repository handle.
  Future<void> lock() async {
    await _repository?.close();
    _repository = null;
    _auth.lock();
  }

  /// Re-encrypts every entry from [oldCrypto] to [newCrypto].
  /// Used by [AuthService.changeMasterPassword].
  Future<void> reencryptAll(
    CryptoService oldCrypto,
    CryptoService newCrypto,
  ) async {
    final oldRepo = VaultRepository(crypto: oldCrypto);
    final newRepo = VaultRepository(crypto: newCrypto);
    final entries = await oldRepo.getAll();
    for (final entry in entries) {
      await newRepo.update(entry);
    }
    await oldRepo.close();
    await newRepo.close();
  }

  /// Changes the master password and re-encrypts the whole vault.
  /// Returns an error string, or null on success.
  Future<String?> changeMasterPassword(
    String currentPassword,
    String newPassword,
  ) async {
    final error = await _auth.changeMasterPassword(
      currentPassword,
      newPassword,
      reencryptAll,
    );
    if (error != null) return error;
    // Rebind the repository to the new key.
    _repository = VaultRepository(crypto: _auth.crypto);
    return null;
  }

  /// Erases the entire vault: all entries, all secure-storage keys.
  /// The app returns to the first-run setup flow afterwards.
  Future<void> eraseVault() async {
    final repo = _repository;
    if (repo != null) {
      await repo.deleteAll();
      await repo.close();
    }
    _repository = null;
    _auth.lock();
  }
}
