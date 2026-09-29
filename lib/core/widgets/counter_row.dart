import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/font_weights.dart';
import '/core/theme/text_styles.dart';
import 'step_button.dart';

/// Tap-to-step counter. Faster than a keyboard for the 0–15 range these
/// fields actually live in, and it can't produce invalid input.
class CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final IconData icon;
  final Color accent;
  final ValueChanged<int> onChanged;

  const CounterRow({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.icon,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs + 2,
      ),
      decoration: AppDecor.well(),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: AppSpace.xs),
          Expanded(child: Text(label, style: AppText.titleSm)),
          StepButton(
            icon: Icons.remove_rounded,
            enabled: value > 0,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: getMonoStyle(
                fontSize: 18,
                weight: FontWeightManager.extraBold,
                color: value == 0
                    ? AppColors.textTertiary
                    : AppColors.textColor,
              ),
            ),
          ),
          StepButton(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
