import 'package:material_ui/material_ui.dart';

import 'screens/lock_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/vault_screen.dart';
import 'services/vault_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VaultKeyApp());
}

/// VaultKey — offline encrypted password manager.
///
/// Startup gate:
/// * No master password yet -> [SetupScreen] (first run).
/// * Master password set -> [LockScreen].
/// * Already unlocked in this session -> [VaultScreen].
class VaultKeyApp extends StatelessWidget {
  const VaultKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultService = VaultService();
    return MaterialApp(
      title: 'VaultKey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _Gate(vaultService: vaultService),
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate({required this.vaultService});

  final VaultService vaultService;

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool? _setupDone;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final done = await widget.vaultService.auth.isSetupDone;
    if (!mounted) return;
    setState(() => _setupDone = done);
  }

  @override
  Widget build(BuildContext context) {
    final setupDone = _setupDone;
    if (setupDone == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.vaultService.isUnlocked) {
      widget.vaultService.bindRepository();
      return VaultScreen(vaultService: widget.vaultService);
    }
    if (setupDone) {
      return LockScreen(vaultService: widget.vaultService);
    }
    return SetupScreen(vaultService: widget.vaultService);
  }
}
