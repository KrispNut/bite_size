import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/neo_progress_bar.dart';
import '/generated/assets.dart';

/// Google's brand guidelines want their mark on a neutral surface, so this
/// stays a light-on-surface button rather than adopting the app's teal — which
/// is also why it isn't a [CustomButton].
class GoogleButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const GoogleButton({super.key, required this.isLoading, required this.onTap});

  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      // Presses by travelling onto its own shadow, exactly as [CustomButton]
      // does. Scaling was the odd one out.
      child: AnimatedSlide(
        offset: _isPressed ? const Offset(0.006, 0.074) : Offset.zero,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.rSm,
            border: Border.all(
              color: AppColors.ink,
              width: AppDecor.strokeWidth,
            ),
            boxShadow: _isPressed ? const [] : AppShadow.raised,
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const NeoProgressBar(width: 64, height: 12)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      Assets.svg.googleLogo.path,
                      width: 20,
                      height: 20,
                      placeholderBuilder: (_) => Icon(
                        Icons.account_circle_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      'Continue with Google',
                      style: getBoldStyle(
                        fontSize: 15,
                        color: AppColors.textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
