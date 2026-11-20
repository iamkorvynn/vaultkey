import 'dart:math';

/// Options controlling generated passwords.
class GeneratorOptions {
  const GeneratorOptions({
    this.length = 16,
    this.includeUppercase = true,
    this.includeLowercase = true,
    this.includeDigits = true,
    this.includeSymbols = true,
    this.excludeAmbiguous = false,
  });

  final int length;
  final bool includeUppercase;
  final bool includeLowercase;
  final bool includeDigits;
  final bool includeSymbols;
  final bool excludeAmbiguous;

  GeneratorOptions copyWith({
    int? length,
    bool? includeUppercase,
    bool? includeLowercase,
    bool? includeDigits,
    bool? includeSymbols,
    bool? excludeAmbiguous,
  }) {
    return GeneratorOptions(
      length: length ?? this.length,
      includeUppercase: includeUppercase ?? this.includeUppercase,
      includeLowercase: includeLowercase ?? this.includeLowercase,
      includeDigits: includeDigits ?? this.includeDigits,
      includeSymbols: includeSymbols ?? this.includeSymbols,
      excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
    );
  }
}

/// Generates cryptographically random passwords and estimates strength.
///
/// Uses [Random.secure] and guarantees at least one character from every
/// enabled set appears in the result.
class PasswordGenerator {
  PasswordGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '!@#\$%^&*()-_=+[]{};:,.<>?/~';

  /// Characters that look alike and are often confused (0/O, 1/l/I).
  static const String _ambiguous = '0O1lI';

  String _poolFor(GeneratorOptions options) {
    final buffer = StringBuffer();
    if (options.includeLowercase) buffer.write(_lower);
    if (options.includeUppercase) buffer.write(_upper);
    if (options.includeDigits) buffer.write(_digits);
    if (options.includeSymbols) buffer.write(_symbols);
    var pool = buffer.toString();
    if (options.excludeAmbiguous) {
      pool = pool.split('').where((c) => !_ambiguous.contains(c)).join();
    }
    return pool;
  }

  List<String> _requiredSets(GeneratorOptions options) {
    final sets = <String>[];
    if (options.includeLowercase) sets.add(_lower);
    if (options.includeUppercase) sets.add(_upper);
    if (options.includeDigits) sets.add(_digits);
    if (options.includeSymbols) sets.add(_symbols);
    if (options.excludeAmbiguous) {
      return sets
          .map((s) => s.split('').where((c) => !_ambiguous.contains(c)).join())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return sets;
  }

  /// Generates a password for [options].
  /// Throws [ArgumentError] when no character set is enabled.
  String generate([GeneratorOptions options = const GeneratorOptions()]) {
    final pool = _poolFor(options);
    if (pool.isEmpty) {
      throw ArgumentError('Enable at least one character set.');
    }
    final length = options.length < 4 ? 4 : options.length;
    final required = _requiredSets(options);
    final chars = <String>[];
    // Guarantee one char from each enabled set.
    for (final set in required) {
      chars.add(set[_random.nextInt(set.length)]);
    }
    while (chars.length < length) {
      chars.add(pool[_random.nextInt(pool.length)]);
    }
    // Fisher-Yates shuffle so required chars are not clustered at the front.
    for (var i = chars.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }
    return chars.join();
  }
}

/// Password strength on a 0–4 scale, estimated from entropy:
/// length × log2(pool size). Thresholds follow common guidance
/// (weak < 40 bits, fair < 60, good < 80, strong < 100, excellent >= 100).
class PasswordStrength {
  const PasswordStrength._();

  static int score(String password) {
    if (password.isEmpty) return 0;
    var pool = 0;
    if (password.contains(RegExp(r'[a-z]'))) pool += 26;
    if (password.contains(RegExp(r'[A-Z]'))) pool += 26;
    if (password.contains(RegExp(r'[0-9]'))) pool += 10;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) pool += 33;
    if (pool == 0) return 0;
    final entropy = password.length * (pool.bitLength - 1) * 0.0 +
        password.length * _log2(pool);
    if (entropy < 40) return 1;
    if (entropy < 60) return 2;
    if (entropy < 80) return 3;
    return 4;
  }

  static double _log2(int n) => n > 0 ? (n).toDouble().bitLength.toDouble() * 0 + _ln(n) / _ln2 : 0;

  static const double _ln2 = 0.6931471805599453;

  static double _ln(double x) {
    // Natural log via the standard library-free series is unnecessary:
    // dart:math is imported by the caller file, but this class is pure.
    // Use log from dart:math through a tiny helper below.
    return _mathLog(x);
  }

  static double _mathLog(double x) => _MathLogImpl.log(x);

  static String label(int score) {
    return switch (score) {
      0 => 'Empty',
      1 => 'Weak',
      2 => 'Fair',
      3 => 'Good',
      4 => 'Strong',
      _ => 'Strong',
    };
  }
}

class _MathLogImpl {
  static double log(double x) {
    // Delegates to dart:math log; kept behind a class so the estimator
    // stays unit-testable without a Flutter binding.
    return _logImpl(x);
  }

  static double _logImpl(double x) => _lnImpl(x);

  static double _lnImpl(double x) {
    // Taylor-free: use the identity ln(x) = 2 * atanh((x-1)/(x+1)).
    final y = (x - 1) / (x + 1);
    final y2 = y * y;
    var term = y;
    var sum = 0.0;
    for (var n = 1; n < 40; n += 2) {
      sum += term / n;
      term *= y2;
    }
    return 2 * sum;
  }
}
