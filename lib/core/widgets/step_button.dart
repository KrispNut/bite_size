import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import 'icon_button.dart';

/// The square +/- next to a stepper value.
///
/// Thin wrapper over [AppIconButton] so the steppers press exactly like every
/// other icon target — it only exists to pin the size and the disabled rule.
class StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const StepButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: icon,
      onTap: enabled ? onTap : null,
      size: 18,
      background: enabled ? AppColors.surface : AppColors.surfaceDim,
    );
  }
}
