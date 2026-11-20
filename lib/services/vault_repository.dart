import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/vault_entry.dart';
import 'crypto_service.dart';

/// SQLite persistence for vault entries.
///
/// The repository owns encryption: callers pass decrypted [VaultEntry]
/// objects and always get decrypted entries back. Only ciphertext is
/// written to disk — see [VaultEntry] for which columns are encrypted.
class VaultRepository {
  VaultRepository({Database? database, CryptoService? crypto})
      : _database = database,
        _crypto = crypto;

  static const String tableName = 'entries';
  static const String databaseName = 'vaultkey.db';
  static const int databaseVersion = 1;

  Database? _database;
  final CryptoService? _crypto;

  CryptoService get _cipher {
    final crypto = _crypto;
    if (crypto == null) {
      throw StateError('VaultRepository needs a CryptoService (unlock first).');
    }
    return crypto;
  }

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;
    final path = p.join(await getDatabasesPath(), databaseName);
    final opened = await openDatabase(
      path,
      version: databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            username_enc TEXT NOT NULL,
            password_enc TEXT NOT NULL,
            url TEXT NOT NULL DEFAULT '',
            notes_enc TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT 'Other',
            favorite INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_entries_title ON $tableName(title)',
        );
        await db.execute(
          'CREATE INDEX idx_entries_category ON $tableName(category)',
        );
      },
    );
    _database = opened;
    return opened;
  }
