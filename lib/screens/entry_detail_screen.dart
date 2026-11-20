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
