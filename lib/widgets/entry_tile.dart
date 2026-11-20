import 'package:material_ui/material_ui.dart';

import '../models/vault_entry.dart';

/// One row in the vault list: avatar letter, title, username and category,
/// plus a favorite star. Tapping opens the detail screen.
class EntryTile extends StatelessWidget {
  const EntryTile({
    required this.entry,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onCopyPassword,
    super.key,
  });

  final VaultEntry entry;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopyPassword;

  @override
  Widget build(BuildContext context) {
    final initial = entry.title.isNotEmpty
        ? entry.title[0].toUpperCase()
        : '?';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initial,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          entry.username.isEmpty ? entry.category : entry.username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                entry.isFavorite ? Icons.star : Icons.star_border,
                color: entry.isFavorite ? Colors.amber : null,
              ),
              tooltip: entry.isFavorite ? 'Unfavorite' : 'Favorite',
              onPressed: onToggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy password',
              onPressed: onCopyPassword,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
