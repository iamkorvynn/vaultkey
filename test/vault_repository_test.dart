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
