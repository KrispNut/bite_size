import 'package:flutter/material.dart';
import '/core/services/sound_service.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/app_icon.dart';

/// One row in the drawer.
///
/// A row, not a card. The drawer is a list of places to go and things to do,
/// and a column of shadowed, stroked, railed cards made every one of them
/// shout at the same volume. Now each row carries exactly one colour signal —
/// the tinted icon box — and the trailing slot says what tapping does:
///
/// * a [badge] is current state (the pack in use, the settled total);
/// * a [chevron] is somewhere to go;
/// * nothing is an action that happens right here.
///
/// Pressing highlights the row instead of moving it: rows in a list are an
/// affordance people already know, and travel-onto-shadow is for tiles.
///
/// [tinted] washes the row in [accent] and is reserved for the destructive
/// tile, so it cannot be mistaken for its neighbours. [quiet] is the
/// opposite — grey icon, secondary text — for leaving.
class DrawerTile extends StatefulWidget {
  final IconData? icon;
  final String? svgAsset;
  final Color accent;
  final String title;
  final String? subtitle;

  /// Current state, shown as a pill: the pack in use, the settled total.
  final String? badge;

  /// True when tapping leaves for another screen.
  final bool chevron;

  /// Washes the row in [accent]. For the danger zone only.
  final bool tinted;

  /// Secondary-coloured throughout. For sign out.
  final bool quiet;

  /// This row is where you already are. Filled and bold, so the drawer has
  /// a "you are here" the moment it opens; tapping it just closes the drawer.
  final bool active;

  /// Overrides both [badge] and [chevron] when given.
  final Widget? trailing;

  /// For a row that flips a setting: whether it is on. Screen readers announce
  /// the row as a switch in that state.
  final bool? switchedOn;

  final VoidCallback onTap;

  const DrawerTile({
    super.key,
    this.icon,
    this.svgAsset,
    required this.accent,
    required this.title,
    this.subtitle,
    this.badge,
    this.chevron = false,
    this.tinted = false,
    this.quiet = false,
    this.active = false,
    this.trailing,
    this.switchedOn,
    required this.onTap,
  });

  @override
  State<DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<DrawerTile> {
  bool _pressed = false;

  Widget? _trailing() {
    if (widget.trailing != null) return widget.trailing;
    if (widget.badge != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: AppDecor.pill(widget.accent, alpha: 0.30),
        child: Text(
          widget.badge!.toUpperCase(),
          style: getMonoStyle(
            fontSize: 9,
            weight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textColor,
          ),
        ),
      );
    }
    if (widget.chevron) {
      return Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
        size: 20,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final end = _trailing();

    final Color background;
    if (widget.tinted) {
      background = AppColors.tint(accent, _pressed ? 0.24 : 0.12);
    } else if (widget.active) {
      background = AppColors.tint(accent, _pressed ? 0.22 : 0.14);
    } else {
      background = _pressed ? AppColors.surfaceAlt : AppColors.transparent;
    }
    final iconFill = widget.quiet
        ? AppColors.surfaceAlt
        : AppColors.tint(accent, widget.tinted || widget.active ? 0.30 : 0.22);
    final titleColor = widget.tinted
        ? accent
        : widget.quiet
        ? AppColors.textSecondary
        : AppColors.textColor;
    final titleStyle = widget.active
        ? getBoldStyle(fontSize: 15, color: titleColor)
        : AppText.titleMd.copyWith(color: titleColor);

    return Semantics(
      button: widget.switchedOn == null,
      selected: widget.active,
      toggled: widget.switchedOn,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          SoundService.instance.playTapSound();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          margin: const EdgeInsets.only(bottom: AppSpace.xxs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs + 2,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.rSm,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconFill,
                  borderRadius: AppRadius.rXs,
                ),
                alignment: Alignment.center,
                child: widget.svgAsset != null
                    ? AppIcon(widget.svgAsset!, size: 20)
                    : Icon(
                        widget.icon,
                        color: widget.quiet ? AppColors.textSecondary : accent,
                        size: 19,
                      ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                  ],
                ),
              ),
              if (end != null) ...[const SizedBox(width: AppSpace.sm), end],
            ],
          ),
        ),
      ),
    );
  }
}
