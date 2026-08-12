import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';

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

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0.0,
    upperBound: 0.04,
  )..addListener(() => setState(() {}));

  bool _isLoading = false;

  bool get _busy => widget.isBusy || _isLoading;
  bool get _enabled => widget.onPress != null && !_busy;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (_enabled) _controller.forward();
  }

  void _onTapCancel() {
    if (_enabled) _controller.reverse();
  }

  Future<void> _handleTap() async {
    if (!_enabled) return;
    _controller.reverse();
    
    final res = widget.onPress!();
    if (res is Future) {
      if (mounted) setState(() => _isLoading = true);
      await res;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.btnColor.a > 0;
    final showGlow = widget.elevated && isFilled && _enabled;

    // Muted palette while disabled or mid-flight so the button reads as inert.
    final bgColor = _enabled
        ? widget.btnColor
        : (isFilled ? AppColors.btnDisabledColor : widget.btnColor);
    final fgColor = _enabled
        ? widget.textColor
        : AppColors.btnDisabledTextColor;
    final outline = widget.borderColor ?? bgColor;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.text,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: (_) => _handleTap(),
        onTapCancel: _onTapCancel,
        child: Transform.scale(
          scale: 1 - _controller.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: AppRadius.rSm,
              border: Border.all(color: _enabled ? outline : AppColors.border),
              color: bgColor,
              boxShadow: showGlow ? AppShadow.glow(widget.btnColor) : null,
            ),
            child: Center(child: _buildContent(fgColor)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color fgColor) {
    if (_busy) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(color: fgColor, strokeWidth: 2.4),
      );
    }

    final label = Text(
      widget.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: getBoldStyle(color: fgColor, fontSize: 15),
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
