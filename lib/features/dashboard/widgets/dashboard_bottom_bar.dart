import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import 'package:provider/provider.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/custom_button.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import 'add_entry_sheet.dart';
import 'roster_closed_notice.dart';

/// Sticky primary action, wrapped in ListenableBuilder listening to ThemeService
/// so theme switches instantly update button & container colors.
class DashboardBottomBar extends StatelessWidget {
  const DashboardBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return Consumer<DashboardViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) return const SizedBox.shrink();

            // No roster means there is no entry to add, so the sticky action
            // has nothing to be.
            final pack = PackService.instance.pack;
            if (!pack.modules.roster) return const SizedBox.shrink();

            final session = viewModel.session;
            if (session?.hasArrived == true) return const SizedBox.shrink();
            final joined = viewModel.myEntry != null;
            // The roster locks when the runner leaves, never on the clock.
            // Postgres enforces this lock (migration 011).
            final locked = session != null && session.hasDeparted;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.bgColor,
                border: Border(
                  top: BorderSide(
                    color: AppColors.ink,
                    width: AppDecor.strokeWidth,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.xs,
                    AppSpace.lg,
                    AppSpace.md,
                  ),
                  child: locked
                      ? RosterClosedNotice(session: session)
                      : CustomButton(
                          onPress: () {
                            debugPrint(
                              '🖱️ [ON_TAP] "${joined ? 'Edit' : 'Add'} My Entry" '
                              'button clicked',
                            );
                            AddEntrySheet.show(context);
                          },
                          text: joined ? 'EDIT MY ENTRY' : 'ADD MY ENTRY',
                          btnColor: AppColors.primary,
                          textColor: AppColors.onPrimary,
                          isIcon: true,
                          iconData: joined
                              ? Icons.edit_rounded
                              : Icons.add_rounded,
                          iconColor: AppColors.onPrimary,
                          height: 56,
                          elevated: true,
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
