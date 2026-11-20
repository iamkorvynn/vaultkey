import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../services/vault_service.dart';
import '../widgets/password_strength_meter.dart';
import 'vault_screen.dart';

/// First-run screen: create the master password that encrypts the vault.
///
/// Nothing is stored anywhere until the user sets a master password.
/// The vault starts empty — no sample entries are ever created.
class SetupScreen extends StatefulWidget {
  const SetupScreen({required this.vaultService, super.key});

  final VaultService vaultService;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createVault() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Enter and confirm your master password.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.vaultService.auth.setupMasterPassword(password);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    widget.vaultService.bindRepository();
    setState(() => _busy = false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VaultScreen(vaultService: widget.vaultService),
      ),
    );
  }
