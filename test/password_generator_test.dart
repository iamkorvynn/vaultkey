import 'package:flutter_test/flutter_test.dart';
import 'package:vaultkey/services/password_generator.dart';

void main() {
  group('PasswordGenerator', () {
    final generator = PasswordGenerator();

    test('generates the requested length', () {
      for (final length in [8, 12, 16, 24, 64]) {
        final password = generator.generate(
          GeneratorOptions(length: length),
        );
        expect(password.length, length);
      }
    });

    test('length below 4 is clamped to 4', () {
      final password = generator.generate(
        const GeneratorOptions(length: 1),
      );
      expect(password.length, 4);
    });

    test('includes at least one char from every enabled set', () {
      for (var i = 0; i < 50; i++) {
        final password = generator.generate(
          const GeneratorOptions(length: 16),
        );
        expect(password.contains(RegExp(r'[a-z]')), isTrue);
        expect(password.contains(RegExp(r'[A-Z]')), isTrue);
        expect(password.contains(RegExp(r'[0-9]')), isTrue);
        expect(password.contains(RegExp(r'[^a-zA-Z0-9]')), isTrue);
      }
    });

    test('digits-only option produces digits only', () {
      final password = generator.generate(
        const GeneratorOptions(
          length: 12,
          includeUppercase: false,
          includeLowercase: false,
          includeSymbols: false,
        ),
      );
      expect(password, matches(RegExp(r'^[0-9]{12}$')));
    });

    test('excludeAmbiguous removes 0 O 1 l I', () {
      for (var i = 0; i < 50; i++) {
        final password = generator.generate(
          const GeneratorOptions(length: 32, excludeAmbiguous: true),
        );
        expect(password.contains(RegExp(r'[0O1lI]')), isFalse);
      }
    });

    test('throws when no character set is enabled', () {
      expect(
        () => generator.generate(
          const GeneratorOptions(
            includeUppercase: false,
            includeLowercase: false,
            includeDigits: false,
            includeSymbols: false,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('two generated passwords are (almost certainly) different', () {
      final a = generator.generate();
      final b = generator.generate();
      expect(a, isNot(equals(b)));
    });
  });

  group('PasswordStrength', () {
    test('empty password scores 0 / Empty', () {
      expect(PasswordStrength.score(''), 0);
      expect(PasswordStrength.label(0), 'Empty');
    });

    test('short lowercase-only password is weak', () {
      expect(PasswordStrength.score('abc'), 1);
      expect(PasswordStrength.label(1), 'Weak');
    });

    test('strength grows with length and charset variety', () {
      final weak = PasswordStrength.score('password');
      final medium = PasswordStrength.score('Password1');
      final strong = PasswordStrength.score('P@ssw0rd!2026#Secure');
      expect(weak, lessThan(medium));
      expect(medium, lessThanOrEqualTo(strong));
      expect(strong, 4);
      expect(PasswordStrength.label(4), 'Strong');
    });

    test('long mixed password scores 4', () {
      expect(PasswordStrength.score('Tr0ub4dor&3xK9!mQw'), 4);
    });

    test('labels cover every score 0-4', () {
      expect(PasswordStrength.label(2), 'Fair');
      expect(PasswordStrength.label(3), 'Good');
    });
  });

  group('GeneratorOptions', () {
    test('copyWith replaces only given fields', () {
      const base = GeneratorOptions(length: 16);
      final next = base.copyWith(length: 24, includeSymbols: false);
      expect(next.length, 24);
      expect(next.includeSymbols, isFalse);
      expect(next.includeDigits, isTrue);
      expect(next.includeUppercase, isTrue);
    });
  });
}
