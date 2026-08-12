import 'package:bite_size/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '/features/chef_ai/widgets/ai_recipe_sheet.dart';
import '/core/alerts/app_alerts.dart';
import '/core/alerts/app_dialogs.dart';
import '/core/shared/custom_button.dart';
import '/core/shared/reusable_appbar.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/core/theme/theme_service.dart';
import 'dashboard_viewmodel.dart';
import 'models/lunch_session.dart';
import 'models/lunch_entry.dart';
import 'widgets/add_entry_sheet.dart';
import 'widgets/bite_size_counter.dart';
import 'widgets/dashboard_drawer.dart';
import '/core/shared/animated_theme_switch.dart';
import '/core/shared/directional_theme_wrapper.dart';
import 'widgets/roster_tile.dart';

/// Main screen: today's Bite Size, the Deficit Detector, the Tandoor Runner
/// and the live roster. Binds to DashboardViewModel.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return DirectionalThemeWrapper(
          child: Scaffold(
            backgroundColor: AppColors.bgColor,
            drawer: const DashboardDrawer(),
            appBar: reusableAppBar(
              title: 'Bite Size',
              subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
              trailingIcon: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.xs),
                  child: Center(child: AnimatedThemeSwitch()),
                ),
              ],
            ),
            body: Consumer<DashboardViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.error != null && !viewModel.isLoading) {
                  return _ErrorState(message: viewModel.error!);
                }
                return Skeletonizer(
                  enabled: viewModel.isLoading,
                  enableSwitchAnimation: true,
                  child: _DashboardBody(viewModel: viewModel),
                );
              },
            ),
            bottomNavigationBar: const _BottomAction(),
          ),
        );
      },
    );
  }
}

/// Sticky primary action, lifted off the content with a soft fade so the list
/// doesn't appear to run underneath a hard edge.
class _BottomAction extends StatelessWidget {
  const _BottomAction();

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const SizedBox.shrink();
        }
        if (viewModel.session?.hasArrived == true ||
            viewModel.session?.hasRunner == true) {
          return const SizedBox.shrink();
        }

        final joined = viewModel.myEntry != null;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgColor.withValues(alpha: 0),
                AppColors.bgColor,
                AppColors.bgColor,
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.md,
                AppSpace.sm,
              ),
              child: CustomButton(
                onPress: () {
                  debugPrint(
                    '🖱️ [ON_TAP] "${joined ? 'Edit My Entry' : 'Add My Entry'}" button clicked',
                  );
                  AddEntrySheet.show(context);
                },
                text: joined ? 'Edit my entry' : 'Add my entry',
                btnColor: AppColors.primary,
                textColor: AppColors.onPrimary,
                isIcon: true,
                iconData: joined ? Icons.edit_rounded : Icons.add_rounded,
                iconColor: AppColors.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardViewModel viewModel;

  const _DashboardBody({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isLoading = Skeletonizer.of(context).enabled;
    // Provide a fake mock session during loading
    final session = isLoading
        ? viewModel.session ??
              LunchSession(
                id: 'mock',
                date: DateTime.now(),
                cutoffAt: DateTime.now(),
                status: SessionStatus.open,
                headcount: 3,
                totalRotis: 6,
                totalPortions: 3,
                arrivedAt: null,
                arrivedByName: null,
                tandoorRunnerName: 'Someone',
                tandoorRunnerId: 'mock',
              )
        : viewModel.session;

    // Provide fake mock entries during loading
    final entries = isLoading && viewModel.entries.isEmpty
        ? [
            const LunchEntry(
              userId: '1',
              userName: 'John Doe',
              dishName: 'Chicken Karahi',
              portions: 2,
              rotisNeeded: 3,
            ),
            const LunchEntry(
              userId: '2',
              userName: 'Jane Smith',
              dishName: 'Daal Mash',
              portions: 1,
              rotisNeeded: 2,
            ),
            const LunchEntry(
              userId: '3',
              userName: 'Ali Raza',
              dishName: 'Nothing',
              portions: 0,
              rotisNeeded: 1,
            ),
          ]
        : viewModel.entries;

    return LiquidPullToRefresh(
      onRefresh: () async {
        viewModel.refresh();
        await Future.delayed(const Duration(milliseconds: 600));
      },
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      showChildOpacityTransition: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.md,
          AppSpace.md,
          AppSpace.huge,
        ),
        children: [
          if (session != null) _CutoffStrip(session: session),
          if (session != null) const SizedBox(height: AppSpace.sm),

          BiteSizeCounter(session: session),
          const SizedBox(height: AppSpace.sm),

          if (session != null) ...[
            if (!session.hasArrived) ...[
              _RunnerCard(viewModel: viewModel, session: session),
              const SizedBox(height: AppSpace.sm),
            ],
            if (session.hasRunner)
              _FoodArrivalCard(viewModel: viewModel, session: session),
          ],

          const SizedBox(height: AppSpace.xl),

          _SectionHeader(
            title: "Today's roster",
            count: entries.length,
            action: _AiChip(onTap: () => AiRecipeSheet.show(context)),
          ),
          const SizedBox(height: AppSpace.sm),

          if (entries.isEmpty)
            const _EmptyRoster()
          else
            ...entries.map(
              (e) =>
                  RosterTile(entry: e, isMe: e.userId == viewModel.currentUid),
            ),
        ],
      ),
    );
  }
}

/// Thin status line above the hero: how long the roster stays open.
class _CutoffStrip extends StatelessWidget {
  final LunchSession session;

  const _CutoffStrip({required this.session});

  @override
  Widget build(BuildContext context) {
    final locked = session.isPastCutoff;
    final accent = locked ? AppColors.warning : AppColors.success;

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Text(
          locked ? 'Roster locked' : 'Roster open',
          style: getSemiBoldStyle(color: accent, fontSize: 12.5),
        ),
        const Spacer(),
        Text(
          locked
              ? 'Closed ${DateFormat.jm().format(session.cutoffAt)}'
              : 'Cutoff ${DateFormat.jm().format(session.cutoffAt)}',
          style: AppText.caption,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? action;

  const _SectionHeader({required this.title, this.count, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppText.h3),
        if (count != null) ...[
          const SizedBox(width: AppSpace.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.rPill,
            ),
            child: Text(
              '$count',
              style: getBoldStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
        const Spacer(),
        ?action,
      ],
    );
  }
}

class _AiChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AiChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: AppRadius.rPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                'AI check',
                style: getBoldStyle(color: AppColors.primary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared shell for the two status cards under the hero.
class _ActionCard extends StatelessWidget {
  final Widget leading;
  final String label;
  final String value;
  final Widget? trailing;

  const _ActionCard({
    required this.leading,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm + 2),
      decoration: AppDecor.card(),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: getBoldStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: getSemiBoldStyle(
                    color: AppColors.textColor,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Circular icon holder used as the leading slot of [_ActionCard].
class _CardIcon extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String? lottieAsset;
  final Color color;

  const _CardIcon({this.icon, this.emoji, this.lottieAsset, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: lottieAsset != null
          ? ClipOval(child: Lottie.asset(lottieAsset!, width: 40, height: 40, fit: BoxFit.cover))
          : emoji != null
              ? Text(emoji!, style: const TextStyle(fontSize: 19))
              : Icon(icon, color: color, size: 21),
    );
  }
}

class _RunnerCard extends StatelessWidget {
  final DashboardViewModel viewModel;
  final LunchSession session;

  const _RunnerCard({required this.viewModel, required this.session});

  Future<void> _claim(BuildContext context, String name) async {
    debugPrint('🖱️ [ON_TAP] "Claim Runner" button clicked for $name');
    ShowToastDialog.showLoader('Assigning runner duty...');
    final error = await viewModel.claimRunner(name);
    ShowToastDialog.closeLoader();
    if (error != null) {
      ShowToastDialog.showToast(error);
    } else {
      ShowToastDialog.showToast('$name is today\'s Tandoor Runner! 🏃');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      leading: _CardIcon(
        icon: session.hasRunner ? null : Icons.directions_run_rounded,
        lottieAsset: session.hasRunner ? Assets.lottie.runner.path : null,
        color: session.hasRunner ? AppColors.success : AppColors.textTertiary,
      ),
      label: 'Tandoor runner',
      value: session.hasRunner
          ? (viewModel.amRunner
                ? '${session.tandoorRunnerName} · you'
                : session.tandoorRunnerName!)
          : 'Nobody yet — who\'s going?',
      trailing: session.hasRunner
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomButton(
                  onPress: () => _claim(context, 'Office Boy'),
                  text: 'Office Boy',
                  width: 96,
                  btnColor: AppColors.transparent,
                  textColor: AppColors.primary,
                  borderColor: AppColors.primaryBorder,
                  isIcon: false,
                  elevated: false,
                  height: 38,
                ),
                const SizedBox(width: AppSpace.xs),
                CustomButton(
                  onPress: () => _claim(context, 'Rana'),
                  text: 'Rana',
                  width: 96,
                  btnColor: AppColors.transparent,
                  textColor: AppColors.primary,
                  borderColor: AppColors.primaryBorder,
                  isIcon: false,
                  elevated: false,
                  height: 38,
                ),
              ],
            ),
    );
  }
}

class _FoodArrivalCard extends StatelessWidget {
  final DashboardViewModel viewModel;
  final LunchSession session;

  const _FoodArrivalCard({required this.viewModel, required this.session});

  Future<void> _markArrived(BuildContext context) async {
    debugPrint('🖱️ [ON_TAP] "Food Has Arrived 🔔" button clicked');

    showCustomConfirmationDialog(
      context,
      'Food Arrived?',
      'Are you sure the food is here? This will notify everyone.',
      () {
        Navigator.of(context).pop();
        
        Future.microtask(() async {
          ShowToastDialog.showLoader('Sending arrival alert...');
          final error = await viewModel.markFoodArrived();
          ShowToastDialog.closeLoader();

          if (error != null) {
            ShowToastDialog.showToast(error);
          } else {
            ShowToastDialog.showToast('LUNCH IS ON THE TABLE! 🔔');
          }
        });
      },
      true,
      confirmLabel: 'Yes, it arrived',
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = this.session;

    if (session.hasArrived) {
      final timeStr = DateFormat.jm().format(session.arrivedAt!.toLocal());
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: AppRadius.rLg,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpace.xxl,
          horizontal: AppSpace.lg,
        ),
        child: Column(
          children: [
            Lottie.asset(Assets.lottie.celebrate, height: 150, repeat: true),
            const SizedBox(height: AppSpace.md),
            Text(
              'Lunch is Served! 🍲',
              style: AppText.h2.copyWith(color: AppColors.success),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Announced by ${session.arrivedByName ?? "the office boy"}\nat $timeStr',
              textAlign: TextAlign.center,
              style: AppText.bodyLg,
            ),
          ],
        ),
      );
    }

    return _ActionCard(
      leading: _CardIcon(emoji: '🔔', color: AppColors.accentWarm),
      label: 'Food arrival',
      value: session.hasRunner
          ? '${session.tandoorRunnerName} is out at the tandoor'
          : 'Waiting for rotis to arrive...',
      trailing: CustomButton(
        onPress: () => _markArrived(context),
        text: 'Arrived',
        btnColor: AppColors.accentWarm,
        textColor: Colors.white,
        isIcon: false,
        elevated: false,
        width: 84,
        height: 38,
      ),
    );
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xxl,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              // surfaceRaised, not surface: this chip must read as *above* the
              // well it sits in, and in dark mode `surface` is darker than it.
              color: AppColors.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: const Text('🍛', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: AppSpace.sm),
          Text('Nobody has joined yet', style: AppText.titleMd),
          const SizedBox(height: 4),
          Text(
            'Add your entry and get the roster rolling.',
            textAlign: TextAlign.center,
            style: AppText.bodySm,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
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
            Text('Connection lost', style: AppText.h2),
            const SizedBox(height: AppSpace.xs),
            Text(
              isNetwork ? 'Waiting for the network to come back...' : message,
              textAlign: TextAlign.center,
              style: AppText.bodySm,
            ),
            const SizedBox(height: AppSpace.xl),
            CustomButton(
              onPress: () => context.read<DashboardViewModel>().refresh(),
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
