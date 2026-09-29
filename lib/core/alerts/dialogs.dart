import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import 'package:lottie/lottie.dart';
import '/generated/assets.dart';
import '/core/widgets/custom_button.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

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
    builder: (_) => PopScope(
      canPop: false,
      // A flat scrim, not a blur. Frosted glass is the one texture this
      // system has no vocabulary for.
      child: ColoredBox(
        color: AppColors.scrim,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: AppDecor.card(radius: AppRadius.lg),
            child: Lottie.asset(
              Assets.lottie.loading.path,
              width: 180,
              height: 180,
            ),
          ),
        ),
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
            content:
                'Are you sure you want to close ${PackService.labels.activityName}?',
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
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: AppDecor.card(radius: AppRadius.lg),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: AppDecor.tinted(
                accent,
                radius: AppRadius.sm,
                shadow: false,
              ),
              alignment: Alignment.center,
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
