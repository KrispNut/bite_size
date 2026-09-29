import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// Skeleton-ish placeholder shown before the first token lands.
class AiThinkingState extends StatelessWidget {
  const AiThinkingState({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Skeletonizer(
        enabled: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: AppDecor.well(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading today\'s roster...',
                style: getSemiBoldStyle(
                  fontSize: 16,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'We have quite a few people today and we need to ensure everyone is well fed.',
                style: getRegularStyle(
                  fontSize: 14,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Looking at what has come in, it seems like we might be a bit '
                'short. Considering topping it up to be safe.',
                style: getRegularStyle(
                  fontSize: 14,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
