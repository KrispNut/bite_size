import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/features/dashboard/models/activity_session.dart';

/// Whether the roster is still open. It only ever locks when the runner
/// leaves, never on the clock (migration 011).
class RosterStatusBar extends StatelessWidget {
  final ActivitySession session;

  const RosterStatusBar({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final locked = session.hasDeparted;
    final accent = locked ? AppColors.danger : AppColors.success;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: accent,
            border: Border.all(color: AppColors.ink),
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Text(
          locked ? 'ROSTER LOCKED' : 'ROSTER OPEN',
          style: getMonoStyle(color: accent, fontSize: 11, letterSpacing: 1.1),
        ),
        if (locked) ...[
          const SizedBox(width: AppSpace.xs),
          Flexible(
            child: Text(
              '· LEFT ${DateFormat.jm().format(session.runnerDepartedAt!.toLocal())}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.monoLabel.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ],
    );
  }
}
