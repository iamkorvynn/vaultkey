import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vaultkey/models/vault_entry.dart';
import 'package:vaultkey/services/crypto_service.dart';
import 'package:vaultkey/services/vault_repository.dart';

void main() {
  late Database db;
  late VaultRepository repo;
  late CryptoService crypto;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await VaultRepository.createSchema(db);
    crypto = CryptoService(CryptoService.deriveKey('test-master', 'salt'));
    repo = VaultRepository(database: db, crypto: crypto);
  });

  tearDown(() async {
    await db.close();
  });

  VaultEntry sampleEntry({String title = 'GitHub'}) {
    return VaultEntry.create(
      title: title,
      username: 'octocat',
      password: 's3cret!',
      url: 'https://github.com',
      notes: 'personal account',
      category: 'Work',
    );
  }

  group('VaultRepository CRUD', () {
    test('starts empty', () async {
      expect(await repo.getAll(), isEmpty);
      expect(await repo.count(), 0);
    });

    test('insert then getAll returns the entry decrypted', () async {
      final entry = sampleEntry();
      await repo.insert(entry);
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.title, 'GitHub');
      expect(all.first.username, 'octocat');
      expect(all.first.password, 's3cret!');
      expect(all.first.notes, 'personal account');
      expect(all.first.url, 'https://github.com');
      expect(all.first.category, 'Work');
    });

    test('secrets are stored encrypted, never plaintext', () async {
      final entry = sampleEntry();
      await repo.insert(entry);
      final rows = await db.query(
        VaultRepository.tableName,
        where: 'id = ?',
        whereArgs: <Object?>[entry.id],
      );
      expect(rows.length, 1);
      final row = rows.first;
      expect(row['username_enc'], isNot('octocat'));
      expect(row['password_enc'], isNot('s3cret!'));
      expect(row['notes_enc'], isNot('personal account'));
      // Title stays plaintext for search.
      expect(row['title'], 'GitHub');
    });

    test('getById returns the entry; unknown id returns null', () async {
      final entry = sampleEntry();
      await repo.insert(entry);
      final found = await repo.getById(entry.id);
      expect(found?.title, 'GitHub');
      expect(await repo.getById('no-such-id'), isNull);
    });

    test('update changes fields and refreshes updatedAt', () async {
      final entry = sampleEntry();
      await repo.insert(entry);
      final updated = entry.copyWith(
        password: 'n3w-p@ss',
        updatedAt: DateTime.now().add(const Duration(seconds: 5)),
      );
      await repo.update(updated);
      final found = await repo.getById(entry.id);
      expect(found?.password, 'n3w-p@ss');
      expect(found?.username, 'octocat');
      expect(
        found!.updatedAt.isAfter(entry.updatedAt),
        isTrue,
      );
    });

    test('delete removes the entry', () async {
      final entry = sampleEntry();
      await repo.insert(entry);
      await repo.delete(entry.id);
      expect(await repo.getAll(), isEmpty);
      expect(await repo.count(), 0);
    });

    test('setFavorite toggles the star', () async {
      final entry = sampleEntry();
      await repo.insert(entry);
      await repo.setFavorite(entry, true);
      expect((await repo.getById(entry.id))?.isFavorite, isTrue);
      await repo.setFavorite(entry, false);
      expect((await repo.getById(entry.id))?.isFavorite, isFalse);
    });

    test('search matches title, username and url (case-insensitive)', () async {
      await repo.insert(sampleEntry(title: 'GitHub'));
      await repo.insert(sampleEntry(title: 'Gmail'));
      await repo.insert(sampleEntry(title: 'Bank App'));

      final byTitle = await repo.search('git');
      expect(byTitle.map((e) => e.title), ['GitHub']);

      final byUser = await repo.search('OCTOCAT');
      expect(byUser.length, 3);

      final byUrl = await repo.search('github.com');
      expect(byUrl.map((e) => e.title), ['GitHub']);

      final empty = await repo.search('');
      expect(empty.length, 3);

      final none = await repo.search('zzz-no-match');
      expect(none, isEmpty);
    });

    test('byCategory filters correctly', () async {
      await repo.insert(sampleEntry(title: 'GitHub'));
      final other = VaultEntry.create(
        title: 'Netflix',
        username: 'me',
        password: 'pw',
        url: '',
        notes: '',
        category: 'Social',
      );
      await repo.insert(other);
      final work = await repo.byCategory('Work');
      expect(work.map((e) => e.title), ['GitHub']);
      final all = await repo.byCategory(null);
      expect(all.length, 2);
    });

    test('deleteAll empties the vault', () async {
      await repo.insert(sampleEntry(title: 'A'));
      await repo.insert(sampleEntry(title: 'B'));
      await repo.deleteAll();
      expect(await repo.count(), 0);
    });

    test('entries encrypted under another key are skipped, not fatal', () async {
      final entry = sampleEntry();
      await repo.insert(entry);
      // Re-open the same rows with a different key.
      final otherCrypto = CryptoService(
        CryptoService.deriveKey('different-master', 'salt'),
      );
      final otherRepo = VaultRepository(database: db, crypto: otherCrypto);
      expect(await otherRepo.getAll(), isEmpty);
      expect(await otherRepo.count(), 1);
    });
  });
}
