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
