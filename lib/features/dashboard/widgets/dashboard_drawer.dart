import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/alerts/dialogs.dart';
import '/core/alerts/toast.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/animated_theme_switch.dart';
import '/features/auth/auth_view.dart';
import '/features/auth/auth_viewmodel.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import '/features/ledger/ledger_view.dart';
import '/generated/assets.dart';
import 'drawer_profile_header.dart';
import 'drawer_tile.dart';
import 'edit_profile_sheet.dart';
import 'pack_picker_sheet.dart';

/// Who you are, where you can go, and the app's settings.
///
/// The two screens come first with no label over them. Settings get a label,
/// the admin-only reset sits apart in its own red group, and sign out is
/// pinned to the bottom, away from everything else.
class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // The light/dark switch lives in here, so the drawer has to repaint the
    // moment it's flipped rather than the next time it opens.
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) => _buildDrawer(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final isDark = ThemeService.instance.isDarkMode;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.sizeOf(context).width * 0.82,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgColor,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppRadius.xl),
            bottomRight: Radius.circular(AppRadius.xl),
          ),
          border: Border(
            right: BorderSide(
              color: AppColors.ink,
              width: AppDecor.strokeWidth,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            DrawerProfileHeader(
              viewModel: viewModel,
              onTap: () => EditProfileSheet.show(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.xs,
                  AppSpace.sm,
                  AppSpace.xs,
                  AppSpace.md,
                ),
                children: [
                  DrawerTile(
                    svgAsset: Assets.svg.tandoor.path,
                    accent: AppColors.primary,
                    title: 'Today',
                    active: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  DrawerTile(
                    svgAsset: Assets.svg.roti.path,
                    accent: AppColors.secondary,
                    title: 'Ledger',
                    chevron: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LedgerView()),
                      );
                    },
                  ),

                  const _SectionLabel('SETTINGS'),
                  DrawerTile(
                    svgAsset: Assets.svg.sparkle.path,
                    accent: AppColors.info,
                    title: 'Theme',
                    badge: PackService.labels.activityName,
                    onTap: () {
                      Navigator.of(context).pop();
                      PackPickerSheet.show(context);
                    },
                  ),
                  DrawerTile(
                    svgAsset: isDark
                        ? Assets.svg.moon.path
                        : Assets.svg.sun.path,
                    accent: AppColors.info,
                    title: 'Dark mode',
                    switchedOn: isDark,
                    // The row already announces the switch and its state.
                    trailing: const ExcludeSemantics(
                      child: AnimatedThemeSwitch(),
                    ),
                    onTap: ThemeService.instance.toggleTheme,
                  ),

                  if (viewModel.isAdmin) ...[
                    const _SectionLabel('DANGER ZONE', danger: true),
                    DrawerTile(
                      icon: Icons.delete_forever_rounded,
                      accent: AppColors.danger,
                      tinted: true,
                      title: 'Reset today\'s data',
                      subtitle: 'Wipes ${PackService.labels.activityName} only',
                      onTap: () => _confirmReset(context, viewModel),
                    ),
                  ],
                ],
              ),
            ),

            // Pinned under a rule, clear of the gesture bar.
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border,
                    width: AppDecor.strokeWidth,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.all(AppSpace.xs),
                child: DrawerTile(
                  icon: Icons.logout_rounded,
                  accent: AppColors.textSecondary,
                  quiet: true,
                  title: 'Sign out',
                  onTap: () => _confirmSignOut(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, DashboardViewModel viewModel) {
    showCustomConfirmationDialog(
      context,
      'Reset today\'s data',
      'This permanently deletes every entry and the session for today. '
          'There is no undo.',
      () async {
        Navigator.of(context).pop();
        await withLoadingOverlay(context, viewModel.resetTodayData);
        if (context.mounted) Navigator.of(context).pop();
      },
      true,
      icon: Icons.delete_forever_rounded,
      accentColor: AppColors.danger,
      confirmLabel: 'Reset',
    );
  }

  void _confirmSignOut(BuildContext context) {
    showCustomConfirmationDialog(
      context,
      'Sign out',
      'You\'ll need to sign in again to see today\'s roster.',
      () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        withLoadingOverlay(context, () async {
          await context.read<AuthViewModel>().signOut();
          appNavigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthView()),
            (route) => false,
          );
        });
      },
      true,
      icon: Icons.logout_rounded,
      accentColor: AppColors.danger,
    );
  }
}

/// The line that opens a group of rows. The rule running off to the right is
/// what makes a group read as a group.
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool danger;

  const _SectionLabel(this.text, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        AppSpace.xl,
        AppSpace.sm,
        AppSpace.xs,
      ),
      child: Row(
        children: [
          Text(text, style: AppText.monoLabel.copyWith(color: color)),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Container(
              height: AppDecor.strokeWidth,
              color: danger
                  ? AppColors.tint(AppColors.danger, 0.45)
                  : AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}
