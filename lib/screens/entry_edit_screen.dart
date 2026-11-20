import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../models/vault_entry.dart';
import '../services/password_generator.dart';
import '../services/vault_service.dart';
import '../widgets/password_strength_meter.dart';

/// Add / edit form for one vault entry. The password field has a
/// one-tap generator and a live strength meter.
class EntryEditScreen extends StatefulWidget {
  const EntryEditScreen({required this.vaultService, this.entry, super.key});

  final VaultService vaultService;

  /// Null when creating a new entry.
  final VaultEntry? entry;

  @override
  State<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _urlController;
  late final TextEditingController _notesController;

  String _category = VaultCategory.other;
  bool _obscurePassword = true;
  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _usernameController = TextEditingController(text: entry?.username ?? '');
    _passwordController = TextEditingController(text: entry?.password ?? '');
    _urlController = TextEditingController(text: entry?.url ?? '');
    _notesController = TextEditingController(text: entry?.notes ?? '');
    _category = entry?.category ?? VaultCategory.other;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final generated = PasswordGenerator().generate(
      const GeneratorOptions(length: 16),
    );
    setState(() {
      _passwordController.text = generated;
      _obscurePassword = false;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final repo = widget.vaultService.repository;
    final existing = widget.entry;
    if (existing == null) {
      final entry = VaultEntry.create(
        title: _titleController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        url: _urlController.text.trim(),
        notes: _notesController.text.trim(),
        category: _category,
      );
      await repo.insert(entry);
      if (!mounted) return;
      Navigator.of(context).pop(entry);
    } else {
      final updated = existing.copyWith(
        title: _titleController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        url: _urlController.text.trim(),
        notes: _notesController.text.trim(),
        category: _category,
        updatedAt: DateTime.now(),
      );
      await repo.update(updated);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    }
  }
