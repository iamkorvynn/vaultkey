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
