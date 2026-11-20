/// Built-in vault categories. Users pick one per entry; filtering and
/// grouping in the vault list is driven by this list.
class VaultCategory {
  const VaultCategory._();

  static const String login = 'Login';
  static const String social = 'Social';
  static const String banking = 'Banking';
  static const String work = 'Work';
  static const String email = 'Email';
  static const String shopping = 'Shopping';
  static const String gaming = 'Gaming';
  static const String other = 'Other';

  /// All categories in display order.
  static const List<String> all = <String>[
    login,
    social,
    banking,
    work,
    email,
    shopping,
    gaming,
    other,
  ];

  /// Returns true when [value] is one of the known categories.
  static bool isKnown(String value) => all.contains(value);

  /// Normalizes an unknown or empty category to [other].
  static String normalize(String? value) {
    if (value == null || value.trim().isEmpty) return other;
    return isKnown(value) ? value : other;
  }
}
