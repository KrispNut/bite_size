import 'package:flutter/material.dart';
import '/core/widgets/screen_name.dart';
import '/core/theme/activity_packs.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/app_bar.dart';
import '/core/widgets/icon_button.dart';
import '/core/widgets/empty_state.dart';
import '/core/widgets/error_state.dart';
import 'ledger_viewmodel.dart';
import 'widgets/ledger_daily_strip_view.dart';
import 'widgets/month_nav_bar.dart';
import '/generated/assets.dart';

class LedgerView extends StatelessWidget {
  const LedgerView({super.key});

  @override
  Widget build(BuildContext context) =>
      ScreenName('Ledger', child: _build(context));

  Widget _build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LedgerViewModel()..loadMonth(),
      child: Consumer<LedgerViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.bgColor,
          appBar: reusableAppBar(
            title: '${PackService.labels.unitPluralTitle} ledger',
            subtitle: vm.monthLabel,
            leadingIcon: Padding(
              padding: const EdgeInsets.all(AppSpace.sm),
              child: AppIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          body: Column(
            children: [
              MonthNavBar(vm: vm),
              Expanded(
                child: vm.error != null && !vm.isLoading
                    ? ErrorState(
                        message: vm.error!,
                        onRetry: vm.loadMonth,
                        title: 'Ledger unavailable',
                      )
                    : Skeletonizer(
                        enabled: vm.isLoading,
                        enableSwitchAnimation: true,
                        child: vm.users.isEmpty && !vm.isLoading
                            ? EmptyState(
                                svgAsset: Assets.svg.roti.path,
                                title: 'No records yet',
                                message:
                                    'Records will appear as team members\n'
                                    'log their daily entries.',
                              )
                            : LedgerDailyStripView(vm: vm),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
