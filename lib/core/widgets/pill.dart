import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// A small tinted badge that states a fact — "Waiting on 2", "Brought food".
///
/// "Pill" is a leftover name: these are square-cornered chips like everything
/// else. Not tappable — if it should do something, use `PillButton`.
class Pill extends StatelessWidget {
  final String label;
  final Color color;

  /// Override for the corner; the default is the system's tightest radius.
  final BorderRadius? radius;

  const Pill({
    super.key,
    required this.label,
    required this.color,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tint(color, 0.24),
        borderRadius: radius ?? AppRadius.rXs,
        border: Border.all(color: AppColors.ink),
      ),
      // Uppercase mono: the design's "interactive chip" role, used for food
      // tags and status counts alike.
      child: Text(
        label.toUpperCase(),
        style: getMonoStyle(
          fontSize: 10,
          color: AppColors.textColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
