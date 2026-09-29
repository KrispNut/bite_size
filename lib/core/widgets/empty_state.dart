import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import 'app_icon.dart';

/// Centred "there's nothing here yet" block.
///
/// Takes an [svgAsset] or an [icon]. [boxed] wraps the block in a bento tile,
/// for empty states that sit inside a list rather than filling a whole page.
///
/// It used to accept a Lottie too. Empty states are, by definition, what you
/// stare at while nothing is happening — an animation looping under that is
/// pure battery for no information.
class EmptyState extends StatelessWidget {
  final String? svgAsset;
  final IconData? icon;
  final String title;
  final String message;
  final bool boxed;

  const EmptyState({
    super.key,
    this.svgAsset,
    this.icon,
    required this.title,
    required this.message,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (svgAsset != null)
          Container(
            width: 64,
            height: 64,
            decoration: AppDecor.card(
              color: AppColors.surfaceRaised,
              radius: AppRadius.sm,
            ),
            alignment: Alignment.center,
            child: AppIcon(svgAsset!, size: 32),
          )
        else
          Icon(icon, size: 56, color: AppColors.textTertiary),
        const SizedBox(height: AppSpace.sm),
        Text(title, style: AppText.h3, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center, style: AppText.bodySm),
      ],
    );

    if (!boxed) return Center(child: body);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xl,
      ),
      alignment: Alignment.center,
      decoration: AppDecor.card(
        color: AppColors.surfaceAlt,
        radius: AppRadius.lg,
      ),
      child: body,
    );
  }
}
