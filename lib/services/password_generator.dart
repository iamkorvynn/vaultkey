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
