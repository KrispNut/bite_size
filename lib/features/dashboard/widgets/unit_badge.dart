import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/font_weights.dart';
import '/core/theme/text_styles.dart';

/// A count of the pack's bulk item with its name underneath, e.g. "3 ROTIS".
///
/// Deliberately a bare figure rather than a filled box: in this design a
/// filled, stroked box means "press me", and this is read-only.
class UnitBadge extends StatelessWidget {
  final int count;

  /// Words after the unit name, e.g. "to buy".
  final String suffix;
  final double fontSize;

  /// Draws in white for the brand-filled runner card.
  final bool onBrand;

  const UnitBadge({
    super.key,
    required this.count,
    this.suffix = '',
    this.fontSize = 22,
    this.onBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    final labels = PackService.labels;
    final unitName = count == 1 ? labels.unit : labels.unitPlural;
    final numberColor = onBrand
        ? AppColors.textOnBrand
        : count == 0
        ? AppColors.textTertiary
        : AppColors.textColor;
    final captionColor = onBrand
        ? AppColors.textOnBrandMuted
        : AppColors.textTertiary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$count',
          style: getMonoStyle(
            color: numberColor,
            fontSize: fontSize,
            weight: FontWeightManager.extraBold,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$unitName $suffix'.trim().toUpperCase(),
          style: getMonoStyle(
            color: captionColor,
            fontSize: 8.5,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}
