import 'package:material_ui/material_ui.dart';

import '../services/secure_store.dart';
import '../services/vault_service.dart';
import 'lock_screen.dart';

/// Settings: auto-lock timeout, biometric toggle, change master password,
/// vault stats, and erase vault.
///
/// Auto-lock options are deliberately short — a password manager should
/// never stay open for long unattended.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.vaultService, super.key});

  final VaultService vaultService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _store = SecureStore();
  int _autoLockMinutes = 2;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  int _entryCount = 0;
  bool _loading = true;

  static const List<int> autoLockChoices = <int>[1, 2, 5, 15];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final minutes = await _store.autoLockMinutes;
    final bioEnabled = await _store.isBiometricEnabled;
    final bioAvailable =
        await widget.vaultService.auth.canUseBiometrics;
    final count = await widget.vaultService.repository.count();
    if (!mounted) return;
    setState(() {
      _autoLockMinutes = minutes;
      _biometricEnabled = bioEnabled;
      _biometricAvailable = bioAvailable;
      _entryCount = count;
      _loading = false;
    });
  }

  Future<void> _setAutoLock(int minutes) async {
    await _store.setAutoLockMinutes(minutes);
    setState(() => _autoLockMinutes = minutes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Auto-lock set to $minutes minute(s).')),
    );
  }

  Future<void> _setBiometric(bool value) async {
    if (value) {
      final ok = await widget.vaultService.auth.authenticateBiometric();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication failed.')),
        );
        return;
      }
    }
    await widget.vaultService.auth.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  Future<void> _changeMasterPassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change master password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match.')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    final error = await widget.vaultService.changeMasterPassword(
      currentController.text,
      newController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Master password changed. Vault re-encrypted.',
        ),
      ),
    );
  }

  Future<void> _eraseVault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase vault?'),
        content: const Text(
          'This deletes every entry and your master password. '
          'There is no backup and no recovery. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.vaultService.eraseVault();
    await _store.deleteAll();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LockScreen(vaultService: widget.vaultService),
      ),
      (_) => false,
    );
  }
