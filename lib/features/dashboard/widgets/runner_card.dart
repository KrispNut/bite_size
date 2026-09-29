import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '/core/alerts/dialogs.dart';
import '/core/alerts/toast.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/custom_button.dart';
import '/core/widgets/dashed_divider.dart';
import '/core/widgets/lottie_loop.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import '/features/dashboard/models/activity_session.dart';
import '/generated/assets.dart';
import 'unit_badge.dart';

class RunnerCard extends StatelessWidget {
  final DashboardViewModel viewModel;
  final ActivitySession session;

  const RunnerCard({super.key, required this.viewModel, required this.session});

  @override
  Widget build(BuildContext context) {
    final hasRunner = session.hasRunner;
    final outsideRunners = PackService.instance.pack.externalRunners;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.sm + 2),
      decoration: hasRunner
          ? AppDecor.filled(AppColors.primaryDeep, shadow: false)
          : AppDecor.card(shadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (!hasRunner && viewModel.isAdmin && outsideRunners.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            _buildAssignButtons(outsideRunners),
          ],
          if (hasRunner) ..._buildNextStep(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hasRunner = session.hasRunner;
    final String name;
    if (hasRunner) {
      name = viewModel.isRunner
          ? '${session.runnerName} · you'
          : session.runnerName!;
    } else {
      name = viewModel.isAdmin
          ? 'Nobody yet — who is going?'
          : 'Not assigned yet';
    }

    return Row(
      children: [
        _RunnerAnimation(hasRunner: hasRunner),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                PackService.labels.runner.toUpperCase(),
                style: AppText.monoLabel.copyWith(
                  color: hasRunner
                      ? AppColors.textOnBrandMuted
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: hasRunner
                    ? AppText.h3.copyWith(color: AppColors.textOnBrand)
                    : AppText.titleMd,
              ),
            ],
          ),
        ),
        if (PackService.modules.units) ...[
          const SizedBox(width: AppSpace.xs),
          UnitBadge(
            count: session.totalUnits,
            suffix: 'to buy',
            fontSize: 26,
            onBrand: hasRunner,
          ),
        ],
      ],
    );
  }

  Widget _buildAssignButtons(List<String> names) {
    final errand = PackService.labels.errand;
    return Row(
      spacing: AppSpace.xs,
      children: [
        for (final name in names)
          Expanded(
            child: CustomButton(
              onPress: () {
                ShowToastDialog.whileLoading(
                  'Assigning the $errand...',
                  () => viewModel.assignRunner(name),
                  success: '$name has the $errand! 🏃',
                );
              },
              text: name,
              btnColor: AppColors.transparent,
              textColor: AppColors.primary,
              isIcon: false,
              elevated: false,
              height: 42,
            ),
          ),
      ],
    );
  }

  /// The bottom half once someone has the errand: already gone, waiting on
  /// answers, or clear to leave.
  List<Widget> _buildNextStep(BuildContext context) {
    final labels = PackService.labels;
    final waitingOn = viewModel.departureBlockReason;
    final List<Widget> step;

    if (session.hasDeparted) {
      final leftAt = DateFormat.jm().format(
        session.runnerDepartedAt!.toLocal(),
      );
      step = [
        _StatusLine(
          icon: Icons.lock_rounded,
          text: 'Left at $leftAt · list locked',
        ),
        _ActionButton(
          text: labels.arrival,
          icon: Icons.notifications_active_rounded,
          onPress: () => _confirmArrival(context),
        ),
      ];
    } else if (waitingOn != null) {
      step = [
        _StatusLine(
          icon: Icons.hourglass_top_rounded,
          iconColor: AppColors.warning,
          text: waitingOn,
        ),
        // Greyed out; the line above says why.
        if (viewModel.canMarkDeparted)
          _ActionButton(
            text: 'Start the ${labels.errand}',
            svgIcon: Assets.svg.runner.path,
          ),
      ];
    } else if (viewModel.canMarkDeparted) {
      step = [
        const _StatusLine(
          icon: Icons.check_rounded,
          text: 'Everything is confirmed — clear to go!',
        ),
        _ActionButton(
          text: 'Start the ${labels.errand}',
          svgIcon: Assets.svg.runner.path,
          onPress: () => _confirmDeparture(context),
        ),
      ];
    } else {
      return const [];
    }

    return [
      const SizedBox(height: AppSpace.sm),
      const DashedDivider(),
      for (final item in step) ...[const SizedBox(height: AppSpace.sm), item],
    ];
  }

  void _confirmDeparture(BuildContext context) {
    final labels = PackService.labels;
    final expenseCount = viewModel.activeExpenseCount;
    final lockedItems = [
      if (expenseCount > 0) labels.expenseCount(expenseCount),
      if (PackService.modules.units) labels.unitCount(session.totalUnits),
    ];

    showCustomConfirmationDialog(
      context,
      'Heading out?',
      lockedItems.isEmpty
          ? 'This locks the list. Nothing can be added after this.'
          : 'This locks the list at ${lockedItems.join(' plus ')}. '
                'Nothing can be added after this.',
      () {
        Navigator.of(context).pop();
        ShowToastDialog.whileLoading(
          'Closing the list...',
          viewModel.markDeparted,
          success: 'Off on the ${labels.errand} — list locked 🏃',
        );
      },
      true,
      icon: Icons.directions_run_rounded,
      confirmLabel: 'Lock it & go',
    );
  }

  void _confirmArrival(BuildContext context) {
    final labels = PackService.labels;
    showCustomConfirmationDialog(
      context,
      '${labels.arrival}?',
      'Are you sure it is here? This will notify everyone.',
      () {
        Navigator.of(context).pop();
        ShowToastDialog.whileLoading(
          'Sending arrival alert...',
          viewModel.markArrived,
          success: '${labels.arrival.toUpperCase()}! 🔔',
        );
      },
      true,
      confirmLabel: 'Yes, it arrived',
    );
  }
}

/// An idle robot while nobody has the errand, the runner once somebody does.
class _RunnerAnimation extends StatelessWidget {
  final bool hasRunner;

  const _RunnerAnimation({required this.hasRunner});

  @override
  Widget build(BuildContext context) {
    final loading = Skeletonizer.maybeOf(context)?.enabled ?? false;

    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: hasRunner
            ? AppColors.surface
            : AppColors.tint(AppColors.primary, 0.18),
        borderRadius: AppRadius.rXs,
        border: AppDecor.stroke,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: loading ? null : _buildAnimation(),
    );
  }

  // Both animations are drawn small inside a 500×500 canvas, so they're
  // scaled up to fill the tile. The robot also sits right of centre in its
  // canvas, hence the nudge left.
  Widget _buildAnimation() {
    if (hasRunner) {
      return Transform.scale(
        scale: 3.8,
        child: _animation(Assets.lottie.runner.path),
      );
    }
    return Transform.translate(
      offset: const Offset(-8, 0),
      child: Transform.scale(
        scale: 1.6,
        child: _animation(Assets.lottie.idle.path),
      ),
    );
  }

  Widget _animation(String path) =>
      LottieLoop(path, key: ValueKey(path), size: const Size.square(56));
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;

  const _StatusLine({required this.icon, this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 16,
            color: iconColor ?? AppColors.textOnBrandMuted,
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Text(
            text,
            style: getSemiBoldStyle(
              color: AppColors.textOnBrand,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// The warm accent button that stands out on the dark card. Takes either a
/// Material [icon] or one of the app's own [svgIcon] marks.
class _ActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? svgIcon;
  final VoidCallback? onPress;

  const _ActionButton({
    required this.text,
    this.icon,
    this.svgIcon,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      onPress: onPress,
      text: text,
      btnColor: AppColors.accentFill,
      textColor: AppColors.onAccent,
      isIcon: true,
      iconData: icon,
      svgData: svgIcon == null
          ? null
          : Opacity(
              opacity: onPress == null ? 0.4 : 1,
              child: AppIcon(svgIcon!, size: 22),
            ),
      elevated: true,
      height: 48,
    );
  }
}
