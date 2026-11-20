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

  group('CryptoService encrypt/decrypt round-trip', () {
    late CryptoService crypto;

    setUp(() {
      crypto = CryptoService(CryptoService.deriveKey('master-pass', 'salt'));
    });

    test('encrypt then decrypt returns the original text', () {
      const plain = 'my-secret-password-123!';
      final cipher = crypto.encryptText(plain);
      expect(crypto.decryptText(cipher), plain);
    });

    test('ciphertext differs from plaintext and looks encrypted', () {
      final cipher = crypto.encryptText('hello');
      expect(cipher, isNot('hello'));
      expect(CryptoService.looksEncrypted(cipher), isTrue);
      expect(CryptoService.looksEncrypted('hello'), isFalse);
    });

    test('same plaintext encrypts differently each time (fresh IV)', () {
      final a = crypto.encryptText('same-password');
      final b = crypto.encryptText('same-password');
      expect(a, isNot(equals(b)));
      expect(crypto.decryptText(a), 'same-password');
      expect(crypto.decryptText(b), 'same-password');
    });

    test('empty string round-trips', () {
      final cipher = crypto.encryptText('');
      expect(crypto.decryptText(cipher), '');
    });

    test('unicode and long text round-trip', () {
      const plain = 'pässwörd 🔐 with ünïcode and a very long tail '
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      expect(crypto.decryptText(crypto.encryptText(plain)), plain);
    });

    test('wrong key cannot decrypt (returns null)', () {
      final cipher = crypto.encryptText('secret');
      final other = CryptoService(
        CryptoService.deriveKey('different-pass', 'salt'),
      );
      expect(other.decryptText(cipher), isNull);
    });

    test('malformed ciphertext returns null instead of throwing', () {
      expect(crypto.decryptText('not-a-cipher'), isNull);
      expect(crypto.decryptText('a:b:c'), isNull);
      expect(crypto.decryptText(':::') , isNull);
    });

    test('empty ciphertext decrypts to empty string (pass-through)', () {
      expect(crypto.decryptText(''), '');
    });

    test('master password verifier matches for the right key only', () {
      final key = CryptoService.deriveKey('master-pass', 'salt');
      final verifier = masterPasswordVerifier(key);
      final other = CryptoService.deriveKey('master-pass', 'other-salt');
      expect(masterPasswordVerifier(key), verifier);
      expect(masterPasswordVerifier(other), isNot(verifier));
    });
  });
}
