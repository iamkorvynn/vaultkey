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

  /// Decrypts one raw database row into a [VaultEntry].
  /// Rows that fail to decrypt are skipped by callers (never crash the list).
  VaultEntry? _decryptRow(Map<String, Object?> row) {
    final username = _cipher.decryptText(row['username_enc'] as String);
    final password = _cipher.decryptText(row['password_enc'] as String);
    final notes = _cipher.decryptText(row['notes_enc'] as String? ?? '');
    if (username == null || password == null || notes == null) return null;
    return VaultEntry.fromDecryptedMap(
      row,
      username: username,
      password: password,
      notes: notes,
    );
  }

  /// Returns every entry, newest first.
  Future<List<VaultEntry>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      orderBy: 'updated_at DESC',
    );
    final entries = <VaultEntry>[];
    for (final row in rows) {
      final entry = _decryptRow(row);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  /// Returns the entry with [id], or null when it does not exist.
  Future<VaultEntry?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _decryptRow(rows.first);
  }

  /// Inserts a new entry (encrypting its secrets first).
  Future<void> insert(VaultEntry entry) async {
    final db = await _db;
    await db.insert(
      tableName,
      entry.toMap(
        encryptedUsername: _cipher.encryptText(entry.username),
        encryptedPassword: _cipher.encryptText(entry.password),
        encryptedNotes: _cipher.encryptText(entry.notes),
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing entry and refreshes its updated timestamp.
  Future<void> update(VaultEntry entry) async {
    final db = await _db;
    final stamped = entry.copyWith(updatedAt: DateTime.now());
    await db.update(
      tableName,
      stamped.toMap(
        encryptedUsername: _cipher.encryptText(stamped.username),
        encryptedPassword: _cipher.encryptText(stamped.password),
        encryptedNotes: _cipher.encryptText(stamped.notes),
      ),
      where: 'id = ?',
      whereArgs: <Object?>[entry.id],
    );
  }

  /// Deletes the entry with [id].
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(tableName, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Toggles the favorite flag for [entry].
  Future<void> setFavorite(VaultEntry entry, bool favorite) async {
    await update(entry.copyWith(isFavorite: favorite));
  }
