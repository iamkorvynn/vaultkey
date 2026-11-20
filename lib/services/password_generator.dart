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
