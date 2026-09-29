import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/custom_button.dart';
import '/generated/assets.dart';

/// Full-screen "this didn't load" state with a retry.
///
/// The dashboard and the ledger each had their own; the ledger's used a bare
/// `ElevatedButton`, which was the only place in the app not going through
/// [CustomButton].
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String title;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Connection lost',
  });

  @override
  Widget build(BuildContext context) {
    // A dropped realtime socket is a network blip, not something the person
    // needs the raw exception text for.
    final isNetwork =
        message.contains('Realtime') || message.contains('stream');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 150,
              width: 190,
              child: Lottie.asset(
                Assets.lottie.noInternet,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => Icon(
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(title, style: AppText.h2),
            const SizedBox(height: AppSpace.xs),
            Text(
              isNetwork ? 'Waiting for the network to come back...' : message,
              textAlign: TextAlign.center,
              style: AppText.bodySm,
            ),
            const SizedBox(height: AppSpace.xl),
            CustomButton(
              onPress: onRetry,
              text: 'Retry',
              btnColor: AppColors.primary,
              textColor: AppColors.onPrimary,
              isIcon: true,
              iconData: Icons.refresh_rounded,
              iconColor: AppColors.onPrimary,
              width: 170,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
