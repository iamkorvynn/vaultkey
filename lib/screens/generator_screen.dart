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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password generator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    _password,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  const SizedBox(height: 8),
                  PasswordStrengthMeter(password: _password),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copy,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _regenerate,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Regenerate'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Length: ${_options.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _options.length.toDouble(),
            min: 8,
            max: 64,
            divisions: 56,
            label: '${_options.length}',
            onChanged: (value) =>
                _updateOptions(_options.copyWith(length: value.round())),
          ),
          SwitchListTile(
            title: const Text('Uppercase letters (A-Z)'),
            value: _options.includeUppercase,
            onChanged: (value) => _updateOptions(
              _options.copyWith(includeUppercase: value),
            ),
          ),
          SwitchListTile(
            title: const Text('Lowercase letters (a-z)'),
            value: _options.includeLowercase,
            onChanged: (value) => _updateOptions(
              _options.copyWith(includeLowercase: value),
            ),
          ),
          SwitchListTile(
            title: const Text('Digits (0-9)'),
            value: _options.includeDigits,
            onChanged: (value) => _updateOptions(
              _options.copyWith(includeDigits: value),
            ),
          ),
          SwitchListTile(
            title: const Text('Symbols (!@#\$...)'),
            value: _options.includeSymbols,
            onChanged: (value) => _updateOptions(
              _options.copyWith(includeSymbols: value),
            ),
          ),
          SwitchListTile(
            title: const Text('Exclude ambiguous characters (0 O 1 l I)'),
            value: _options.excludeAmbiguous,
            onChanged: (value) => _updateOptions(
              _options.copyWith(excludeAmbiguous: value),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generated on this device with a secure random source. '
            'Nothing is sent anywhere.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
