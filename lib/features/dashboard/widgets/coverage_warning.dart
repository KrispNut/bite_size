import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// One line, and only when there is something to say: the roster is short.
///
/// "Everyone is covered · 100%" was a whole card celebrating the normal
/// case. Nobody needs to be told that; they need to be told when it isn't
/// true, so this renders nothing at all unless what was brought falls short
/// of the headcount.
class CoverageWarning extends StatelessWidget {
  final int headcount;
  final int covers;

  const CoverageWarning({
    super.key,
    required this.headcount,
    required this.covers,
  });

  @override
  Widget build(BuildContext context) {
    final deficit = headcount - covers;
    if (headcount == 0 || deficit <= 0) return const SizedBox.shrink();

    final labels = PackService.labels;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs + 2,
      ),
      decoration: AppDecor.tinted(
        AppColors.accentWarm,
        radius: AppRadius.sm,
        shadow: false,
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 17,
            color: AppColors.accentWarm,
          ),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              'Short by ${labels.coverCount(deficit)} for $headcount on '
              'the roster.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: getSemiBoldStyle(color: AppColors.textColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
