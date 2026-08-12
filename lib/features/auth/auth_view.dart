import 'dart:ui';
import 'package:bite_size/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '/core/alerts/app_dialogs.dart';
import '/core/alerts/app_alerts.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/core/theme/theme_service.dart';
import '/features/dashboard/dashboard_view.dart';
import 'auth_viewmodel.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bgColor,
          body: Stack(
            children: [
              // Ambient brand wash behind the header.
              Positioned(
                top: -100,
                right: -100,
                child: _Glow(size: 500, color: AppColors.primary, opacity: 0.3),
              ),
              Positioned(
                bottom: -50,
                left: -150,
                child: _Glow(
                  size: 450,
                  color: AppColors.accentWarm,
                  opacity: 0.25,
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: MediaQuery.of(context).size.width * 0.2,
                child: _Glow(
                  size: 300,
                  color: AppColors.success,
                  opacity: 0.15,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.lg,
                          ),
                          child: Consumer<AuthViewModel>(
                            builder: (context, viewModel, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 24,
                                    sigmaY: 24,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppSpace.xl),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black.withValues(alpha: 0.2)
                                          : Colors.white.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Lottie.asset(
                                          Assets.lottie.hourglassLoading.path,
                                          height: 140,
                                        ),
                                        const SizedBox(height: AppSpace.sm),
                                        Text(
                                          'Bite Size',
                                          style: getExtraBoldStyle(
                                            fontSize: 38,
                                            color: AppColors.primary,
                                          ).copyWith(letterSpacing: -1),
                                        ),
                                        const SizedBox(height: AppSpace.xs),
                                        Text(
                                          'Office lunch logistics, sorted before noon.',
                                          textAlign: TextAlign.center,
                                          style: getMediumStyle(
                                            fontSize: 15,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpace.xl),
                                        if (viewModel.error != null) ...[
                                          _ErrorBanner(
                                            message: viewModel.error!,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // Sign-in stays pinned to the bottom so the CTA never
                    // scrolls out of reach on short devices.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.xl,
                        AppSpace.md,
                        AppSpace.xl,
                        AppSpace.lg + 10,
                      ),
                      child: Consumer<AuthViewModel>(
                        builder: (context, viewModel, _) {
                          return Column(
                            children: [
                              _GoogleButton(
                                isLoading: viewModel.isLoading,
                                onTap: () async {
                                  final success = await withLoadingOverlay(
                                    context,
                                    () => viewModel.signInWithGoogle(),
                                  );
                                  if (success) {
                                    appNavigatorKey.currentState
                                        ?.pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const DashboardView(),
                                          ),
                                        );
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Glow({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: AppDecor.tinted(AppColors.danger, radius: AppRadius.sm),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              message,
              style: getMediumStyle(fontSize: 12.5, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Google's brand guidelines want their mark on a neutral surface, so this
/// stays a light-on-surface button rather than adopting the app's teal.
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.rSm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rSm,
            border: Border.all(color: AppColors.borderStrong),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                )
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
