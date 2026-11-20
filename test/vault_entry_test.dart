import 'package:flutter_test/flutter_test.dart';
import 'package:vaultkey/models/category.dart';
import 'package:vaultkey/models/vault_entry.dart';

void main() {
  group('VaultEntry', () {
    test('create assigns id and timestamps, not favorite', () {
      final entry = VaultEntry.create(
        title: 'GitHub',
        username: 'octocat',
        password: 'pw',
        url: '',
        notes: '',
        category: 'Work',
      );
      expect(entry.id.isNotEmpty, isTrue);
      expect(entry.isFavorite, isFalse);
      expect(entry.createdAt, isNotNull);
      expect(entry.updatedAt, isNotNull);
    });

    test('copyWith replaces only given fields', () {
      final entry = VaultEntry.create(
        title: 'GitHub',
        username: 'octocat',
        password: 'pw',
        url: '',
        notes: '',
        category: 'Work',
      );
      final next = entry.copyWith(title: 'GitLab', isFavorite: true);
      expect(next.title, 'GitLab');
      expect(next.isFavorite, isTrue);
      expect(next.id, entry.id);
      expect(next.username, 'octocat');
    });

    test('toMap/fromDecryptedMap round-trip preserves fields', () {
      final entry = VaultEntry.create(
        title: 'GitHub',
        username: 'octocat',
        password: 'pw',
        url: 'https://github.com',
        notes: 'note',
        category: 'Work',
      );
      final map = entry.toMap(
        encryptedUsername: 'ENC-USER',
        encryptedPassword: 'ENC-PASS',
        encryptedNotes: 'ENC-NOTES',
      );
      expect(map['username_enc'], 'ENC-USER');
      expect(map['title'], 'GitHub');
      final restored = VaultEntry.fromDecryptedMap(
        map,
        username: 'octocat',
        password: 'pw',
        notes: 'note',
      );
      expect(restored.id, entry.id);
      expect(restored.title, 'GitHub');
      expect(restored.password, 'pw');
      expect(restored.category, 'Work');
    });

    test('equality is by id', () {
      final a = VaultEntry.create(
        title: 'A',
        username: '',
        password: '',
        url: '',
        notes: '',
        category: 'Other',
      );
      final b = a.copyWith(title: 'B');
      expect(a, equals(b));
      final c = VaultEntry.create(
        title: 'A',
        username: '',
        password: '',
        url: '',
        notes: '',
        category: 'Other',
      );
      expect(a, isNot(equals(c)));
    });
  });

  group('VaultCategory', () {
    test('all contains the 8 built-in categories', () {
      expect(VaultCategory.all.length, 8);
      expect(VaultCategory.all, contains('Banking'));
    });

    test('normalize returns Other for unknown/empty values', () {
      expect(VaultCategory.normalize(null), 'Other');
      expect(VaultCategory.normalize(''), 'Other');
      expect(VaultCategory.normalize('Weird'), 'Other');
      expect(VaultCategory.normalize('Work'), 'Work');
    });
  });
}
