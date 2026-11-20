import 'package:material_ui/material_ui.dart';

import '../services/vault_service.dart';
import 'vault_screen.dart';

/// Unlock screen: enter the master password, or use biometrics when
/// enabled. Failed attempts count down to a temporary lockout.
class LockScreen extends StatefulWidget {
  const LockScreen({required this.vaultService, super.key});

  final VaultService vaultService;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _error;
  int _attemptsLeft = 5;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final auth = widget.vaultService.auth;
    final available = await auth.canUseBiometrics;
    final enabled = await auth.isBiometricEnabled;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
    if (available && enabled) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final crypto = await widget.vaultService.auth.unlockWithBiometrics();
    if (crypto == null) return;
    if (!mounted) return;
    _openVault();
  }

  void _openVault() {
    widget.vaultService.bindRepository();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VaultScreen(vaultService: widget.vaultService),
      ),
    );
  }

  Future<void> _unlock() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Enter your master password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = widget.vaultService.auth;
    final lockout = await auth.lockoutRemaining();
    if (lockout != null) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Too many attempts. Try again in '
            '${lockout.inSeconds} seconds.';
      });
      return;
    }
    final crypto = await auth.verifyMasterPassword(password);
    if (!mounted) return;
    if (crypto == null) {
      final left = await auth.attemptsLeft;
      setState(() {
        _busy = false;
        _attemptsLeft = left;
        _error = left > 0
            ? 'Wrong password. $left attempt${left == 1 ? '' : 's'} left.'
            : 'Too many attempts. Locked for 1 minute.';
      });
      return;
    }
    setState(() => _busy = false);
    _openVault();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
