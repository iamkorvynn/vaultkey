import 'package:flutter_test/flutter_test.dart';
import 'package:vaultkey/services/crypto_service.dart';

void main() {
  group('CryptoService key derivation', () {
    test('same password + salt derives the same key', () {
      final a = CryptoService.deriveKey('hunter2', 'salt-1');
      final b = CryptoService.deriveKey('hunter2', 'salt-1');
      expect(a, equals(b));
    });

    test('different salts derive different keys', () {
      final a = CryptoService.deriveKey('hunter2', 'salt-1');
      final b = CryptoService.deriveKey('hunter2', 'salt-2');
      expect(a, isNot(equals(b)));
    });

    test('different passwords derive different keys', () {
      final a = CryptoService.deriveKey('hunter2', 'salt-1');
      final b = CryptoService.deriveKey('hunter3', 'salt-1');
      expect(a, isNot(equals(b)));
    });

    test('derived key is 32 bytes (AES-256)', () {
      final key = CryptoService.deriveKey('hunter2', 'salt-1');
      expect(key.length, 32);
    });

    test('generateSalt returns distinct random salts', () {
      final a = CryptoService.generateSalt();
      final b = CryptoService.generateSalt();
      expect(a, isNot(equals(b)));
      expect(a.isNotEmpty, isTrue);
    });
  });
