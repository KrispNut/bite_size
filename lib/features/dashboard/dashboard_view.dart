import 'package:flutter/material.dart';
import '/core/widgets/screen_name.dart';
import '/core/theme/activity_packs.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/animated_app_logo_title.dart';
import '/core/widgets/app_bar.dart';
import '/core/widgets/directional_theme_wrapper.dart';
import '/core/widgets/error_state.dart';
import 'dashboard_viewmodel.dart';
import 'widgets/dashboard_body.dart';
import 'widgets/dashboard_bottom_bar.dart';
import 'widgets/dashboard_drawer.dart';
import 'widgets/ping_button.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) =>
      ScreenName('Dashboard', child: _build(context));

  Widget _build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return DirectionalThemeWrapper(
          child: Scaffold(
            backgroundColor: AppColors.bgColor,
            drawer: const DashboardDrawer(),
            appBar: reusableAppBar(
              title: PackService.labels.activityName,
              titleWidget: AnimatedAppLogoTitle(
                title: PackService.labels.activityName,
                subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
              ),
              subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
              trailingIcon: const [PingButton()],
            ),
            body: Consumer<DashboardViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.error != null && !viewModel.isLoading) {
                  return ErrorState(
                    message: viewModel.error!,
                    onRetry: viewModel.refresh,
                  );
                }
                return Skeletonizer(
                  enabled: viewModel.isLoading,
                  enableSwitchAnimation: true,
                  child: DashboardBody(viewModel: viewModel),
                );
              },
            ),
            bottomNavigationBar: const DashboardBottomBar(),
          ),
        );
      },
    );
  }
}
