import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// Section Header with title on the far left, and count badge + action button
/// stuck together on the far right matching the design mockup.
class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Far Left: Section Title
        Text(title, style: AppText.h3),

        // Far Right: Count Badge + Action Button stuck together
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadius.rXs,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppDecor.strokeWidth,
                  ),
                ),
                child: Text(
                  '$count',
                  style: getMonoStyle(color: AppColors.textColor, fontSize: 11),
                ),
              ),
            ],
            if (count != null && action != null)
              const SizedBox(width: AppSpace.xs),
            ?action,
          ],
        ),
      ],
    );
  }
}
