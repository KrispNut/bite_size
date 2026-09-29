import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import 'app_icon.dart';

/// A one-line explanatory strip: a mark on the left, a sentence on the right.
///
/// For sections that are empty but where the emptiness isn't a problem — it
/// just needs explaining. Louder than a caption, quieter than [EmptyState].
class HintBanner extends StatelessWidget {
  final String svgAsset;
  final String message;

  const HintBanner({super.key, required this.svgAsset, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecor.card(color: AppColors.surfaceAlt),
      child: Row(
        children: [
          AppIcon(svgAsset, size: 22),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(message, style: AppText.bodySm)),
        ],
      ),
    );
  }
}
