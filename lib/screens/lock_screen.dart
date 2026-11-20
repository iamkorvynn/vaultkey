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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock, size: 64),
                const SizedBox(height: 16),
                Text(
                  'VaultKey is locked',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your master password to unlock your vault.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Master password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _unlock,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unlock'),
                ),
                if (_biometricAvailable && _biometricEnabled) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _tryBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Unlock with biometrics'),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  '$_attemptsLeft attempts left before a 1-minute lockout.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
