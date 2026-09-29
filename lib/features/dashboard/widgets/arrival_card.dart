import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/app_icon.dart';
import '/features/dashboard/models/activity_session.dart';
import '/generated/assets.dart';

/// Replaces [RunnerCard] once the errand is done: it's here, who said so,
/// and when.
class ArrivalCard extends StatelessWidget {
  final ActivitySession session;

  const ArrivalCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final labels = PackService.labels;
    final arrivedAt = DateFormat.jm().format(session.arrivedAt!.toLocal());

    return Container(
      width: double.infinity,
      decoration: AppDecor.tinted(
        AppColors.success,
        radius: AppRadius.lg,
        shadow: false,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpace.xxl,
        horizontal: AppSpace.lg,
      ),
      child: Column(
        children: [
          AppIcon(Assets.svg.party.path, size: 96),
          const SizedBox(height: AppSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(Assets.svg.party.path, size: 26),
              const SizedBox(width: AppSpace.xs),
              Text(
                labels.arrival,
                style: AppText.h2.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Announced by ${session.arrivedByName ?? labels.outsider}\n'
            'at $arrivedAt',
            textAlign: TextAlign.center,
            style: AppText.bodyLg,
          ),
        ],
      ),
    );
  }
}
