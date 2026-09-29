import 'package:flutter/material.dart';
import '/core/services/sound_service.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// The small tinted chip that sits at the end of a section header — "AI check",
/// "Add", "Everyone".
///
/// Secondary by definition: the primary action on any screen is a
/// [CustomButton], and this should never compete with it.
class PillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// Defaults to the brand colour; pass an accent for a chip that belongs to a
  /// differently-coloured section.
  final Color? color;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tint = widget.color ?? AppColors.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        SoundService.instance.playTapSound();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedSlide(
        offset: _isPressed ? const Offset(0.03, 0.12) : Offset.zero,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.tint(tint, _isPressed ? 0.34 : 0.22),
            borderRadius: AppRadius.rXs,
            border: Border.all(
              color: AppColors.ink,
              width: AppDecor.strokeWidth,
            ),
            // Chips press like buttons do: shadow gone, body moved onto it.
            boxShadow: _isPressed ? const [] : AppShadow.card,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 14, color: tint),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label.toUpperCase(),
                  style: AppText.monoLabel.copyWith(color: tint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
