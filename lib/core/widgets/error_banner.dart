import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// Inline "that didn't work" strip, for errors that belong next to the thing
/// that caused them rather than taking over the screen.
class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: AppDecor.tinted(AppColors.danger, radius: AppRadius.sm),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              message,
              style: getMediumStyle(fontSize: 12.5, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
