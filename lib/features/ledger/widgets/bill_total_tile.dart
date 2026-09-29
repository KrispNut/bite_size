import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/font_weights.dart';
import '/core/theme/text_styles.dart';

class BillTotalTile extends StatelessWidget {
  final double total;

  /// What the bill covers, e.g. "September 2026".
  final String caption;

  const BillTotalTile({super.key, required this.total, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecor.filled(
        AppColors.primaryDeep,
        radius: AppRadius.lg,
        shadow: false,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -14,
            child: Icon(
              Icons.restaurant_rounded,
              size: 110,
              color: AppColors.textOnBrand.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TOTAL BILL',
                style: getMonoStyle(
                  fontSize: 12,
                  color: AppColors.textOnBrand.withValues(alpha: 0.8),
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      PackService.currency.symbol,
                      style: getMonoStyle(
                        fontSize: 22,
                        weight: FontWeightManager.extraBold,
                        color: AppColors.textOnBrand.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      total.round().toString(),
                      style: getMonoStyle(
                        fontSize: 48,
                        weight: FontWeightManager.extraBold,
                        color: AppColors.textOnBrand,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: AppRadius.rXs,
                  border: Border.all(color: AppColors.textOnBrand),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: AppColors.textOnBrand,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      caption,
                      style: getMonoStyle(
                        fontSize: 12,
                        color: AppColors.textOnBrand,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
