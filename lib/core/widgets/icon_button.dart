import 'package:flutter/material.dart';
import '/core/services/sound_service.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';

/// The square icon chip. Every icon-only tap target in the app is one of these.
///
/// Material's `IconButton` gives you a circular ripple on a shapeless
/// background; this is a proper little bento tile — ink stroke, hard offset,
/// and the same press-onto-its-own-shadow travel as `CustomButton`. Passing a
/// null [onTap] disables it, which flattens the shadow and greys the glyph.
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? background;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.background,
    this.size = 20,
    this.tooltip,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final down = _pressed || !_enabled;
    final fg = _enabled
        ? (widget.color ?? AppColors.textColor)
        : AppColors.textTertiary;

    final button = GestureDetector(
      onTapDown: (_) {
        if (_enabled) setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (!_enabled) return;
        setState(() => _pressed = false);
        SoundService.instance.playTapSound();
        widget.onTap!();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedSlide(
        offset: down ? const Offset(0.05, 0.1) : Offset.zero,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.background ?? AppColors.surface,
            borderRadius: AppRadius.rXs,
            border: Border.all(
              color: AppColors.ink,
              width: AppDecor.strokeWidth,
            ),
            boxShadow: down ? const [] : AppShadow.card,
          ),
          child: Icon(widget.icon, size: widget.size, color: fg),
        ),
      ),
    );

    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}
