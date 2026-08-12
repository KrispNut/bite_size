import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '/generated/assets.dart';
import '/core/shared/custom_button.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';

/// Wraps an async action with a full-screen Lottie loading overlay.
Future<T> withLoadingOverlay<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: Colors.transparent,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Theme.of(dialogContext).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          Center(
            child: Lottie.asset(
              Assets.lottie.loading.path,
              width: 264,
              height: 264,
            ),
          ),
        ],
      ),
    ),
  );

  try {
    return await action();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

/// Shared confirm/acknowledge dialog.
///
/// Pass `isCancelButton: false` for a single-button acknowledgement.
void showCustomConfirmationDialog(
  BuildContext context,
  String title,
  String content,
  VoidCallback? onTap,
  bool? isCancelButton, {
  bool barrierDismissible = true,
  IconData? icon,
  Color? accentColor,
  String confirmLabel = 'Yes',
  String cancelLabel = 'Cancel',
}) {
  final bool hasCancel = isCancelButton != false;
  final IconData resolvedIcon =
      icon ??
      (hasCancel ? Icons.warning_amber_rounded : Icons.info_outline_rounded);

  showDialog<String>(
    barrierDismissible: barrierDismissible,
    barrierColor: AppColors.scrim,
    context: context,
    builder: (context) {
      return _DialogShell(
        icon: resolvedIcon,
        accent: accentColor ?? AppColors.primary,
        title: title,
        content: content,
        primaryLabel: hasCancel ? confirmLabel : 'Ok',
        onPrimary: onTap ?? () => Navigator.pop(context),
        secondaryLabel: hasCancel ? cancelLabel : null,
        onSecondary: () => Navigator.pop(context),
      );
    },
  );
}

Future<bool> showExitConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: AppColors.scrim,
        builder: (context) {
          return _DialogShell(
            icon: Icons.logout_rounded,
            accent: AppColors.danger,
            title: 'Exit app',
            content: 'Are you sure you want to close Bite Size?',
            primaryLabel: 'Exit',
            onPrimary: () => Navigator.of(context).pop(true),
            secondaryLabel: 'Stay',
            onSecondary: () => Navigator.of(context).pop(false),
          );
        },
      ) ??
      false;
}

class _DialogShell extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String content;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback onSecondary;

  const _DialogShell({
    required this.icon,
    required this.accent,
    required this.title,
    required this.content,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 25),
            ),
            const SizedBox(height: AppSpace.md),
            Text(title, style: AppText.h3, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              content,
              style: getRegularStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                if (secondaryLabel != null) ...[
                  Expanded(
                    child: CustomButton(
                      onPress: onSecondary,
                      text: secondaryLabel!,
                      btnColor: AppColors.transparent,
                      textColor: AppColors.textSecondary,
                      borderColor: AppColors.border,
                      isIcon: false,
                      elevated: false,
                      height: 46,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                ],
                Expanded(
                  child: CustomButton(
                    onPress: onPrimary,
                    text: primaryLabel,
                    btnColor: accent,
                    textColor: Colors.white,
                    isIcon: false,
                    elevated: false,
                    height: 46,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
