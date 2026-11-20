import 'package:material_ui/material_ui.dart';

import '../models/vault_entry.dart';
import '../services/clipboard_service.dart';
import '../services/vault_service.dart';
import 'entry_edit_screen.dart';

/// Shows one entry in full: title, username, password (hidden until
/// revealed), URL, notes, category and favorite state. Copy buttons use
/// the auto-clearing clipboard.
class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({
    required this.vaultService,
    required this.entry,
    super.key,
  });

  final VaultService vaultService;
  final VaultEntry entry;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  final _clipboard = ClipboardService();
  late VaultEntry _entry;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  @override
  void dispose() {
    _clipboard.dispose();
    super.dispose();
  }

  Future<void> _copy(String label, String value, {bool secret = false}) async {
    if (secret) {
      await _clipboard.copySecret(value);
    } else {
      await _clipboard.copy(value);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          secret
              ? '$label copied — clipboard clears in 30 seconds.'
              : '$label copied.',
        ),
      ),
    );
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<VaultEntry>(
      MaterialPageRoute<VaultEntry>(
        builder: (_) => EntryEditScreen(
          vaultService: widget.vaultService,
          entry: _entry,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _entry = updated);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Delete "${_entry.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.vaultService.repository.delete(_entry.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _toggleFavorite() async {
    final updated = _entry.copyWith(isFavorite: !_entry.isFavorite);
    await widget.vaultService.repository.setFavorite(updated, updated.isFavorite);
    if (!mounted) return;
    setState(() => _entry = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_entry.title),
        actions: [
          IconButton(
            icon: Icon(
              _entry.isFavorite ? Icons.star : Icons.star_border,
              color: _entry.isFavorite ? Colors.amber : null,
            ),
            tooltip: 'Favorite',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FieldRow(
            label: 'Username',
            value: _entry.username.isEmpty ? '—' : _entry.username,
            onCopy: _entry.username.isEmpty
                ? null
                : () => _copy('Username', _entry.username),
          ),
          _FieldRow(
            label: 'Password',
            value: _passwordVisible ? _entry.password : '••••••••',
            onCopy: () => _copy('Password', _entry.password, secret: true),
            trailing: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              tooltip: _passwordVisible ? 'Hide password' : 'Show password',
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
          _FieldRow(
            label: 'URL',
            value: _entry.url.isEmpty ? '—' : _entry.url,
            onCopy: _entry.url.isEmpty
                ? null
                : () => _copy('URL', _entry.url),
          ),
          _FieldRow(
            label: 'Category',
            value: _entry.category,
          ),
          if (_entry.notes.isNotEmpty)
            _FieldRow(
              label: 'Notes',
              value: _entry.notes,
              onCopy: () => _copy('Notes', _entry.notes),
            ),
          const SizedBox(height: 16),
          Text(
            'Created ${_entry.createdAt.toLocal()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Last updated ${_entry.updatedAt.toLocal()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// One labeled field with an optional copy button.
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    this.onCopy,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                trailing ?? const SizedBox.shrink(),
                if (onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy $label',
                    onPressed: onCopy,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
