import 'package:material_ui/material_ui.dart';

import '../services/clipboard_service.dart';
import '../services/password_generator.dart';
import '../widgets/password_strength_meter.dart';

/// Standalone password generator: length slider, charset toggles,
/// regenerate, and copy (auto-clearing clipboard).
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _clipboard = ClipboardService();
  final _generator = PasswordGenerator();
  GeneratorOptions _options = const GeneratorOptions();
  String _password = '';

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  @override
  void dispose() {
    _clipboard.dispose();
    super.dispose();
  }

  void _regenerate() {
    try {
      setState(() => _password = _generator.generate(_options));
    } on ArgumentError {
      // No character set enabled — keep the old password and show a hint.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable at least one character set.'),
        ),
      );
    }
  }

  Future<void> _copy() async {
    if (_password.isEmpty) return;
    await _clipboard.copySecret(_password);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied — clipboard clears in 30 seconds.'),
      ),
    );
  }

  void _updateOptions(GeneratorOptions next) {
    setState(() => _options = next);
    _regenerate();
  }
