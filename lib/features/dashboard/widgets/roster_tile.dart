import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/features/dashboard/models/lunch_entry.dart';

/// One person's contribution to today's lunch.
class RosterTile extends StatelessWidget {
  final LunchEntry entry;
  final bool isMe;

  const RosterTile({super.key, required this.entry, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    final broughtNothing = entry.portions == 0;
    final photoUrl = entry.userPhotoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(
          color: isMe ? AppColors.primaryBorder : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      // IntrinsicHeight lets the accent rail match whatever height the content
      // settles at, instead of guessing a fixed one.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent rail marks your own row without shouting.
            if (isMe) Container(width: 3.5, color: AppColors.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm + 2,
                  vertical: AppSpace.sm,
                ),
                child: Row(
                  children: [
                    _Avatar(
                      name: entry.userName,
                      photoUrl: photoUrl,
                      dimmed: broughtNothing,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            broughtNothing ? 'Eating only' : entry.dishName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: getBoldStyle(
                              color: broughtNothing
                                  ? AppColors.textTertiary
                                  : AppColors.textColor,
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isMe
                                      ? '${entry.userName} · You'
                                      : entry.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: getMediumStyle(
                                    color: isMe
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              if (!broughtNothing) ...[
                                const SizedBox(width: 6),
                                _Tag(
                                  label: 'feeds ${entry.portions}',
                                  color: AppColors.success,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    _RotiBadge(count: entry.rotisNeeded),
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

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool dimmed;

  const _Avatar({
    required this.name,
    required this.photoUrl,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final tint = dimmed ? AppColors.textTertiary : AppColors.primary;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.withValues(alpha: 0.12),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
        image: hasPhoto
            ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(initial, style: getExtraBoldStyle(color: tint, fontSize: 16)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.rXs,
      ),
      child: Text(label, style: getSemiBoldStyle(color: color, fontSize: 11)),
    );
  }
}

class _RotiBadge extends StatelessWidget {
  final int count;

  const _RotiBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final none = count == 0;

    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: none
            ? AppColors.surfaceAlt
            : AppColors.accentWarm.withValues(alpha: 0.12),
        borderRadius: AppRadius.rSm,
        border: Border.all(
          color: none
              ? AppColors.border
              : AppColors.accentWarm.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: getExtraBoldStyle(
              color: none ? AppColors.textTertiary : AppColors.accentWarm,
              fontSize: 17,
              height: 1.1,
            ),
          ),
          Text(
            count == 1 ? 'roti' : 'rotis',
            style: getMediumStyle(
              color: none ? AppColors.textTertiary : AppColors.accentWarm,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
