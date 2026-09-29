import 'package:flutter_svg/flutter_svg.dart';
import '/core/theme/activity_packs.dart';

import '/generated/assets.dart';
import 'package:flutter/material.dart';
import '/core/widgets/screen_name.dart';
import 'package:provider/provider.dart';
import '/core/alerts/dialogs.dart';
import '/core/alerts/toast.dart';
import '/core/theme/app_colors.dart';
import '/core/widgets/error_banner.dart';
import 'widgets/google_button.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/features/dashboard/dashboard_view.dart';
import 'auth_viewmodel.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) =>
      ScreenName('Sign in', child: _build(context));

  Widget _build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bgColor,
          body: SafeArea(
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
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpace.xl),
                            decoration: AppDecor.card(radius: AppRadius.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset(Assets.svg.splashImage.path),
                                const SizedBox(height: AppSpace.md),
                                Text(
                                  PackService.labels.activityName,
                                  style: getExtraBoldStyle(
                                    fontSize: 38,
                                    color: AppColors.textColor,
                                  ).copyWith(letterSpacing: -1),
                                ),
                                const SizedBox(height: AppSpace.xxs),
                                Text(
                                  PackService.labels.tagline,
                                  textAlign: TextAlign.center,
                                  style: getMonoStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 1.1,
                                    height: 1.5,
                                  ),
                                ),
                                if (viewModel.error != null) ...[
                                  const SizedBox(height: AppSpace.lg),
                                  ErrorBanner(message: viewModel.error!),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.xl,
                    AppSpace.md,
                    AppSpace.xl,
                    AppSpace.lg + 10,
                  ),
                  child: Consumer<AuthViewModel>(
                    builder: (context, viewModel, _) {
                      return GoogleButton(
                        isLoading: viewModel.isLoading,
                        onTap: () async {
                          final success = await withLoadingOverlay(
                            context,
                            () => viewModel.signInWithGoogle(),
                          );
                          if (success) {
                            appNavigatorKey.currentState?.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const DashboardView(),
                              ),
                            );
                          } else if (viewModel.error != null) {
                            ShowToastDialog.showToast(viewModel.error!);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
