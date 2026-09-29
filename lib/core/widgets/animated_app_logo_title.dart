import 'dart:math';
import '/core/theme/activity_packs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/services/sound_service.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/app_icon.dart';
import '/generated/assets.dart';

class AnimatedAppLogoTitle extends StatefulWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const AnimatedAppLogoTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  State<AnimatedAppLogoTitle> createState() => _AnimatedAppLogoTitleState();
}

class _AnimatedAppLogoTitleState extends State<AnimatedAppLogoTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 550),
    vsync: this,
  );

  int _comboCount = 0;
  int _calmIndex = 0;
  DateTime? _lastTapTime;

  /// The phrases the badge cycles through belong to the pack — an office
  /// lunch has different jokes from a cricket booking. A pack that names none
  /// falls back to its own name, which is always safe.
  List<String> get _calmPhrases {
    final fromPack = PackService.labels.taglines;
    return fromPack.isNotEmpty ? fromPack : [PackService.labels.activityName];
  }

  static const List<String> _burstEmojis = [
    '✨',
    '🔥',
    '💥',
    '⚡',
    '🎉',
    '👏',
    '🙌',
  ];

  late String _currentBadgeText = _calmPhrases[0];
  late Color _badgeColor = AppColors.accentWarm;
  final Random _random = Random();
  late List<_ParticleData> _particles = [];

  void _onTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 650) {
      _comboCount++;
    } else {
      _comboCount = 1;
    }
    _lastTapTime = now;

    // Generate random particle velocities for floating burst
    _particles = List.generate(5, (i) {
      final angle = (i * (2 * pi / 5)) + (_random.nextDouble() * 0.4 - 0.2);
      final speed = 25.0 + _random.nextDouble() * 20.0;
      return _ParticleData(
        emoji: _burstEmojis[_random.nextInt(_burstEmojis.length)],
        targetDx: cos(angle) * speed,
        targetDy: -sin(angle).abs() * speed - 15.0,
      );
    });

    // Determine badge message & visual variation based on combo level
    if (_comboCount == 1) {
      _currentBadgeText = _calmPhrases[_calmIndex % _calmPhrases.length];
      _calmIndex++;
      _badgeColor = AppColors.accentWarm;
      SoundService.instance.playTapSound();
    } else if (_comboCount == 2) {
      _currentBadgeText = 'Combo 2x! 🔥';
      _badgeColor = AppColors.primary;
      HapticFeedback.selectionClick();
    } else if (_comboCount == 3) {
      _currentBadgeText = 'Chomp 3x! ⚡';
      _badgeColor = AppColors.accentWarm;
      HapticFeedback.mediumImpact();
    } else if (_comboCount == 4) {
      _currentBadgeText = 'FRENZY 4x! 🥖';
      _badgeColor = AppColors.danger;
      HapticFeedback.mediumImpact();
    } else if (_comboCount == 5) {
      _currentBadgeText = 'SUPER 5x! 🚀';
      _badgeColor = AppColors.primaryDeep;
      HapticFeedback.heavyImpact();
    } else {
      _currentBadgeText = _comboCount >= 100
          ? 'x$_comboCount! 👑'
          : 'ULTRA x$_comboCount! 👑';
      _badgeColor = AppColors.success;
      HapticFeedback.heavyImpact();
    }

    _controller.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnim = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 1.14, end: 0.95), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
      ],
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final pulseRadiusAnim = Tween<double>(
      begin: 1.0,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    final pulseOpacityAnim = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    final badgeOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          return Transform.scale(
            scale: scaleAnim.value,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Floating Particle Burst Emojis
                if (_controller.isAnimating)
                  ..._particles.map((p) {
                    final dx = p.targetDx * progress;
                    final dy = p.targetDy * progress;
                    final opacity = (1.0 - progress).clamp(0.0, 1.0);
                    final scale = 0.6 + (progress * 0.6);

                    return Positioned(
                      left: 12 + dx,
                      top: 10 + dy,
                      child: IgnorePointer(
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: Text(
                              p.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Radial Pulse Wave Ring behind logo
                        if (_controller.isAnimating)
                          Transform.scale(
                            scale: pulseRadiusAnim.value,
                            child: Opacity(
                              opacity: pulseOpacityAnim.value,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _badgeColor.withValues(alpha: 0.35),
                                  border: Border.all(
                                    color: _badgeColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: AppDecor.strokeWidth,
                            ),
                          ),
                          child: AppIcon(Assets.svg.roti.path, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: getExtraBoldStyle(
                                  color: AppColors.textColor,
                                  fontSize: 21,
                                ),
                              ),
                              // Inline pop badge (fitted to shrink & scale down smoothly if tight)
                              if (_controller.isAnimating) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Opacity(
                                      opacity: badgeOpacityAnim.value,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _badgeColor,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: AppShadow.card,
                                        ),
                                        child: Text(
                                          _currentBadgeText,
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: AppColors.textOnBrand,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              widget.subtitle!.toUpperCase(),
                              style: AppText.monoLabel,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ParticleData {
  final String emoji;
  final double targetDx;
  final double targetDy;

  const _ParticleData({
    required this.emoji,
    required this.targetDx,
    required this.targetDy,
  });
}
