import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/pill.dart';
import '/core/widgets/user_avatar.dart';
import '/features/dashboard/models/roster_entry.dart';
import 'unit_badge.dart';

class RosterTile extends StatelessWidget {
  final RosterEntry entry;
  final bool isMe;

  const RosterTile({super.key, required this.entry, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    final broughtNothing = entry.covers == 0;
    final photoUrl = entry.userPhotoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      decoration: AppDecor.card(
        color: isMe ? AppColors.primarySoft : AppColors.surface,
        radius: AppRadius.md,
        shadow: false,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMe) Container(width: 6, color: AppColors.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm + 2,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: isMe
                          ? BoxDecoration(
                              borderRadius: AppRadius.rSm,
                              border: Border.all(
                                color: AppColors.primary,
                                width: AppDecor.strokeWidth,
                              ),
                            )
                          : null,
                      padding: isMe ? const EdgeInsets.all(2) : EdgeInsets.zero,
                      child: UserAvatar(
                        name: entry.userName,
                        photoUrl: photoUrl,
                        dimmed: broughtNothing,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // What they brought is the row's headline; who
                          // brought it is the caption. The avatar already
                          // says "a person", so the name can be small.
                          Text(
                            broughtNothing
                                ? PackService.labels.attendingOnly
                                : entry.contribution,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: getBoldStyle(
                              color: broughtNothing
                                  ? AppColors.textTertiary
                                  : AppColors.textColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isMe
                                      ? '${entry.userName} · you'
                                      : entry.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: getMediumStyle(
                                    color: isMe
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (!broughtNothing &&
                                  PackService.modules.coverage) ...[
                                const SizedBox(width: 6),
                                Pill(
                                  label: PackService.labels.coverCount(
                                    entry.covers,
                                  ),
                                  color: AppColors.success,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (PackService.modules.units) ...[
                      const SizedBox(width: AppSpace.xs),
                      // Fixed width keeps the counts in a straight column.
                      SizedBox(
                        width: 46,
                        child: UnitBadge(count: entry.unitsTaken),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
