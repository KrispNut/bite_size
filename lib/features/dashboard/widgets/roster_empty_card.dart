import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/tactile_container.dart';
import '/core/widgets/user_avatar.dart';

class RosterEmptyCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback? onTap;

  const RosterEmptyCard({
    super.key,
    required this.name,
    this.photoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labels = PackService.labels;
    final canAdd = onTap != null;
    final String hint;
    if (!canAdd) {
      hint = 'The roster locked before anyone signed up.';
    } else if (PackService.modules.units) {
      hint =
          'Tap to add your ${labels.contribution} and how many '
          '${labels.unitPlural} you want.';
    } else {
      hint = 'Tap to add your ${labels.contribution}.';
    }

    return TactileContainer(
      onTap: onTap,
      builder: (context, flat) => Container(
        width: double.infinity,
        padding: AppSpace.card,
        decoration: AppDecor.card(radius: AppRadius.lg, shadow: !flat),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EmptySlot(name: name, photoUrl: photoUrl, showAddMark: canAdd),
            const SizedBox(height: AppSpace.md),
            Text(
              canAdd ? "Nobody's signed up yet" : 'Nobody signed up',
              style: AppText.h3,
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              hint,
              style: getMediumStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A roster row waiting to be filled in, laid out like [RosterTile] so it
/// previews what you're about to add.
class _EmptySlot extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool showAddMark;

  const _EmptySlot({
    required this.name,
    required this.photoUrl,
    required this.showAddMark,
  });

  @override
  Widget build(BuildContext context) {
    final radius = AppRadius.md;

    return CustomPaint(
      foregroundPainter: _DashedOutlinePainter(
        color: AppColors.ink,
        radius: radius,
        strokeWidth: AppDecor.strokeWidth,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: [
            UserAvatar(name: name, photoUrl: photoUrl),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your ${PackService.labels.contribution}?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getBoldStyle(
                      color: AppColors.textTertiary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name.isEmpty ? 'You' : '$name · you',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getMediumStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (showAddMark) ...[
              const SizedBox(width: AppSpace.xs),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.rXs,
                  border: AppDecor.stroke,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A dashed rounded-rectangle outline: the "empty slot" mark.
class _DashedOutlinePainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const _DashedOutlinePainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(strokeWidth / 2),
          Radius.circular(radius),
        ),
      );

    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
