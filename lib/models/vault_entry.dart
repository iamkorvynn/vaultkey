/// A single vault entry.
///
/// Privacy model: [title], [url] and [category] are stored in plain text so
/// the vault can be searched and filtered without decrypting every row.
/// [username], [password] and [notes] are stored AES-encrypted; only the
/// encrypted ciphertext ever touches the SQLite database.
class VaultEntry {
  const VaultEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.notes,
    required this.category,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a brand-new entry with a fresh id and timestamps.
  factory VaultEntry.create({
    required String title,
    required String username,
    required String password,
    required String url,
    required String notes,
    required String category,
  }) {
    final now = DateTime.now();
    return VaultEntry(
      id: '${now.microsecondsSinceEpoch}',
      title: title,
      username: username,
      password: password,
      url: url,
      notes: notes,
      category: category,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Returns a copy with the given fields replaced.
  VaultEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? url,
    String? notes,
    String? category,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return VaultEntry(
      id: id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
