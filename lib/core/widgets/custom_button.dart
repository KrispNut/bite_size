import 'package:flutter/material.dart';
import '/core/services/sound_service.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import 'neo_progress_bar.dart';

/// The app's primary action button.
///
/// Handles its own press animation and async busy state: if [onPress] returns
/// a `Future`, the button shows a spinner until it settles, and swallows
/// repeat taps while in flight.
class CustomButton extends StatefulWidget {
  final Function()? onPress;
  final String text;
  final Color btnColor;
  final Color textColor;
  final Color? borderColor;
  final Color? iconColor;
  final bool isIcon;
  final double? width;
  final double height;
  final IconData? iconData;
  final Widget? svgData;

  /// Drops the coloured glow under filled buttons (use inside dense rows).
  final bool elevated;

  /// Forces the busy state from outside, e.g. while a parent form submits.
  final bool isBusy;

  const CustomButton({
    super.key,
    required this.onPress,
    required this.text,
    required this.btnColor,
    this.textColor = Colors.white,
    this.borderColor,
    required this.isIcon,
    this.width = double.infinity,
    this.height = 52,
    this.iconColor,
    this.iconData,
    this.svgData,
    this.elevated = true,
    this.isBusy = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isLoading = false;
  bool _pressed = false;

  bool get _busy => widget.isBusy || _isLoading;
  bool get _enabled => widget.onPress != null && !_busy;

  void _onTapDown(_) {
    if (_enabled) setState(() => _pressed = true);
  }

  void _onTapCancel() {
    if (_pressed) setState(() => _pressed = false);
  }

  Future<void> _handleTap() async {
    if (!_enabled) return;
    SoundService.instance.playActionSound();
    setState(() => _pressed = false);

    final res = widget.onPress!();
    if (res is Future) {
      if (mounted) setState(() => _isLoading = true);
      await res;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// How far the button travels when pressed. It has to exactly match the
  /// shadow offset — the whole illusion is the button sliding down to cover
  /// its own shadow, so any mismatch leaves a visible sliver.
  static const Offset _pressTravel = Offset(2, 4);

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.btnColor.a > 0;

    // Muted palette while disabled or mid-flight so the button reads as inert.
    final bgColor = _enabled
        ? widget.btnColor
        : (isFilled ? AppColors.btnDisabledColor : widget.btnColor);
    final fgColor = _enabled
        ? widget.textColor
        : AppColors.btnDisabledTextColor;

    // Pressed and disabled both sit flat on the surface: a shadow under a
    // button you can't press is a promise the button doesn't keep.
    final down = _pressed || !_enabled;
    final offset = down ? _pressTravel : Offset.zero;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.text,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: (_) => _handleTap(),
        onTapCancel: _onTapCancel,
        child: AnimatedSlide(
          offset: Offset(
            offset.dx / (widget.width ?? 200),
            offset.dy / widget.height,
          ),
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: AppRadius.rSm,
              border: Border.all(
                color: AppColors.ink,
                width: AppDecor.strokeWidth,
              ),
              color: bgColor,
              boxShadow: down
                  ? const []
                  : (widget.elevated ? AppShadow.raised : AppShadow.card),
            ),
            child: Center(child: _buildContent(fgColor)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color fgColor) {
    if (_busy) {
      return NeoProgressBar(
        width: 56,
        height: 12,
        color: fgColor,
        trackColor: AppColors.tint(AppColors.ink, 0.12, base: widget.btnColor),
      );
    }

    // Uppercase is the system's, not the caller's — every label goes through
    // here so no screen has to remember to shout.
    final label = Text(
      widget.text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: getExtraBoldStyle(
        color: fgColor,
        fontSize: 15,
        letterSpacing: 0.8,
      ),
    );

    if (!widget.isIcon) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        widget.svgData ??
            Icon(widget.iconData, size: 20, color: widget.iconColor ?? fgColor),
        const SizedBox(width: AppSpace.xs),
        Flexible(child: label),
      ],
    );
  }
}
