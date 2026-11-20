import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Cryptographic helpers for the vault.
///
/// Design:
/// * The master password never leaves memory in plain form for long: it is
///   stretched into a 256-bit AES key with an iterated SHA-256 KDF
///   (10,000 rounds over password + per-device salt).
/// * Every encrypted value gets a fresh random 16-byte IV, so two identical
///   passwords encrypt to different ciphertext.
/// * Ciphertext is stored as `base64(iv):base64(ciphertext)`.
class CryptoService {
  CryptoService(this._keyBytes);

  /// Number of KDF rounds. High enough to slow brute force, low enough to
  /// keep unlock snappy on a phone.
  static const int kdfRounds = 10000;

  final List<int> _keyBytes;

  enc.Encrypter get _encrypter =>
      enc.Encrypter(enc.AES(enc.Key(_keyBytes), mode: enc.AESMode.cbc));

  /// Derives a 32-byte AES key from [password] and a per-device [salt].
  static List<int> deriveKey(String password, String salt) {
    var digest = sha256.convert(utf8.encode('$salt::$password')).bytes;
    for (var i = 1; i < kdfRounds; i++) {
      digest = sha256.convert(digest).bytes;
    }
    return digest;
  }

  /// Generates a fresh random salt (32 bytes, base64).
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
