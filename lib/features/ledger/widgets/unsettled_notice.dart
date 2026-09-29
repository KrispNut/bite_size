import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// Units with no bill behind them would otherwise silently read as zero.
class UnsettledNotice extends StatelessWidget {
  final int count;

  const UnsettledNotice({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: AppDecor.tinted(AppColors.warning),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: AppColors.warning),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'day has' : 'days have'} '
              '${PackService.labels.unitPlural} but no '
              'bill entered yet — those aren\'t counted in the totals.',
              style: getMediumStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
