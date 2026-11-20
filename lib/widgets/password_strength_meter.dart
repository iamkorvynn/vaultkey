import 'package:material_ui/material_ui.dart';

import '../services/password_generator.dart';

/// A 4-segment strength bar with a label, driven by
/// [PasswordStrength.score].
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final score = PasswordStrength.score(password);
    final label = PasswordStrength.label(score);
    final color = switch (score) {
      0 => Colors.grey,
      1 => Colors.red,
      2 => Colors.orange,
      3 => Colors.lightGreen,
      _ => Colors.green,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 1; i <= 4; i++)
              Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: i <= score ? color : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          password.isEmpty ? 'Enter a password' : 'Strength: $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
