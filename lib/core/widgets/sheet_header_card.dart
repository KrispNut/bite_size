import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// The deep-teal title block at the top of a bottom sheet.
///
/// The sheet's heading is a bento tile of its own rather than loose text, so a
/// sheet opens with the same structural language as the screen behind it.
class SheetHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const SheetHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecor.filled(AppColors.primaryDeep, radius: AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: getExtraBoldStyle(
              fontSize: 22,
              color: AppColors.textOnBrand,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: getMediumStyle(
              fontSize: 14,
              color: AppColors.textOnBrand.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
