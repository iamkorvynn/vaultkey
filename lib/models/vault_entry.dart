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

  /// Serializes the entry for SQLite. The [username], [password] and
  /// [notes] values passed here must already be encrypted ciphertext —
  /// this class never sees the encryption key.
  Map<String, Object?> toMap({
    required String encryptedUsername,
    required String encryptedPassword,
    required String encryptedNotes,
  }) {
    return <String, Object?>{
      'id': id,
      'title': title,
      'username_enc': encryptedUsername,
      'password_enc': encryptedPassword,
      'url': url,
      'notes_enc': encryptedNotes,
      'category': category,
      'favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Builds a decrypted entry from a database row. The encrypted columns
  /// must already have been decrypted by the caller.
  factory VaultEntry.fromDecryptedMap(
    Map<String, Object?> row, {
    required String username,
    required String password,
    required String notes,
  }) {
    return VaultEntry(
      id: row['id'] as String,
      title: row['title'] as String,
      username: username,
      password: password,
      url: (row['url'] as String?) ?? '',
      notes: notes,
      category: (row['category'] as String?) ?? 'Other',
      isFavorite: (row['favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VaultEntry(id: $id, title: $title, category: $category)';
}
