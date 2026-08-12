import 'package:flutter/material.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/features/dashboard/models/lunch_session.dart';

/// Hero card: the roti count for today, plus how well the salan covers the room.
///
/// Deliberately compact — it sits above three more cards and a roster, so it
/// earns roughly one fifth of the viewport, not half of it. Everything reads
/// in one horizontal sweep: count on the left, who/what on the right, status
/// underneath.
class BiteSizeCounter extends StatelessWidget {
  final LunchSession? session;

  const BiteSizeCounter({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final totalRotis = session?.totalRotis ?? 0;
    final headcount = session?.headcount ?? 0;
    final portions = session?.totalPortions ?? 0;

    final deficit = headcount - portions;
    final isShort = deficit > 0;
    final isEmpty = headcount == 0;
    // Clamped so an over-catered day still renders a full — not overflowing — bar.
    final coverage = headcount == 0
        ? 0.0
        : (portions / headcount).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: AppDecor.heroGradient(radius: AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            top: -70,
            right: -30,
            child: _Bloom(size: 160, opacity: 0.14),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TODAY'S TANDOOR ORDER",
                      style: getBoldStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (session?.isPastCutoff == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LOCKED',
                              style: getBoldStyle(
                                color: Colors.white,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        emoji: '🫓',
                        label: 'Rotis',
                        value: '$totalRotis',
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _StatBox(
                        emoji: '👥',
                        label: 'People',
                        value: '$headcount',
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _StatBox(
                        emoji: '🍲',
                        label: 'Portions',
                        value: '$portions',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  children: [
                    Icon(
                      isEmpty
                          ? Icons.schedule_rounded
                          : (isShort
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded),
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isEmpty
                            ? 'Waiting for the first entry'
                            : (isShort
                                  ? 'Short by $deficit ${deficit == 1 ? 'portion' : 'portions'}'
                                  : 'Everyone is covered'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getSemiBoldStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!isEmpty)
                      Text(
                        'Coverage: ${(coverage * 100).toInt()}%',
                        style: getBoldStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _CoverageBar(value: coverage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatBox({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: getExtraBoldStyle(color: Colors.white, fontSize: 26, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: getMediumStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft radial highlight used to give the flat gradient some depth.
class _Bloom extends StatelessWidget {
  final double size;
  final double opacity;

  const _Bloom({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: opacity),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverageBar extends StatelessWidget {
  final double value;

  const _CoverageBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.rPill,
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.3)),
            ),
            FractionallySizedBox(
              widthFactor: value,
              child: const ColoredBox(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
