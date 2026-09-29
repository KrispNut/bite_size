import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/features/dashboard/models/activity_session.dart';

/// Replaces the "Add my entry" button once the runner has departed. That is
/// the only thing that ever locks the roster, so the notice names who left
/// and when.
class RosterClosedNotice extends StatelessWidget {
  final ActivitySession session;

  const RosterClosedNotice({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final leftAt = session.runnerDepartedAt;
    final who = session.runnerName?.split(' ').first;
    final text = leftAt == null
        ? 'Roster locked — the ${PackService.labels.runner} has left'
        : 'Roster locked — ${who ?? 'the ${PackService.labels.runner}'} left '
              'at ${DateFormat.jm().format(leftAt.toLocal())}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm + 2,
        vertical: AppSpace.sm + 2,
      ),
      decoration: AppDecor.tinted(AppColors.warning),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpace.xs),
          Flexible(
            child: Text(
              text,
              style: getSemiBoldStyle(color: AppColors.warning, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
