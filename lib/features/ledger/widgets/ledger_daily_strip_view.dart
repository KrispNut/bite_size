import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import 'package:intl/intl.dart';
import '/core/alerts/dialogs.dart';
import '/core/services/sound_service.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/font_weights.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/custom_button.dart';
import '/core/widgets/empty_state.dart';
import '/core/widgets/tactile_container.dart';
import '/core/widgets/user_avatar.dart';
import '/features/ledger/ledger_viewmodel.dart';
import '/generated/assets.dart';
import 'edit_units_dialog.dart';
import 'ledger_metrics.dart';
import 'month_summary.dart';
import 'settle_month_sheet.dart';
import 'unsettled_notice.dart';

/// Redesigned ledger view featuring a top horizontal date strip, user roster cards,
/// and a prominent "CONFIRM & SETTLE" action bar matching the target aesthetic.
class LedgerDailyStripView extends StatefulWidget {
  final LedgerViewModel vm;

  const LedgerDailyStripView({super.key, required this.vm});

  @override
  State<LedgerDailyStripView> createState() => _LedgerDailyStripViewState();
}

class _LedgerDailyStripViewState extends State<LedgerDailyStripView> {
  final ScrollController _dateStripController = ScrollController();

  @override
  void dispose() {
    _dateStripController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate(List<DateTime> days, DateTime selected) {
    final index = days.indexWhere(
      (d) =>
          d.year == selected.year &&
          d.month == selected.month &&
          d.day == selected.day,
    );
    if (index != -1 && _dateStripController.hasClients) {
      const itemWidth = 68.0;
      final targetOffset = (index * itemWidth) - 120.0;
      _dateStripController.animateTo(
        targetOffset.clamp(0.0, _dateStripController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Settling is monthly: one price per unit for every day not yet billed.
  Widget _buildSettleButton(BuildContext context) {
    final month = DateFormat('MMMM').format(widget.vm.currentMonth);
    final hasUnsettled = widget.vm.unsettledSessionIds.isNotEmpty;
    return CustomButton(
      onPress: hasUnsettled
          ? () => SettleMonthSheet.show(context, widget.vm)
          : null,
      text: hasUnsettled ? 'Settle $month' : 'Nothing to settle in $month',
      btnColor: AppColors.primary,
      textColor: AppColors.onPrimary,
      isIcon: true,
      iconData: hasUnsettled
          ? Icons.receipt_long_rounded
          : Icons.check_circle_rounded,
      elevated: true,
      height: 52,
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.vm.monthDays;
    final selectedDate = widget.vm.selectedDate;
    final dateKey = LedgerMetrics.dateKeyOf(selectedDate);
    final dayUnits = widget.vm.dayTotalUnits(dateKey);
    final dayCost = widget.vm.dayTotalCost(dateKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(days, selectedDate);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.xs),
          child: MonthSummary(vm: widget.vm),
        ),
        Container(
          height: 82,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: AppDecor.strokeWidth,
              ),
            ),
          ),
          child: days.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  controller: _dateStripController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isSelected =
                        day.year == selectedDate.year &&
                        day.month == selectedDate.month &&
                        day.day == selectedDate.day;

                    final key = LedgerMetrics.dateKeyOf(day);
                    final units = widget.vm.dayTotalUnits(key);

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpace.xs),
                      child: TactileContainer(
                        onTap: () {
                          SoundService.instance.playTapSound();
                          widget.vm.selectDate(day);
                        },
                        builder: (context, pressed) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: AppRadius.rMd,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 2.0 : AppDecor.strokeWidth,
                            ),
                            boxShadow: (isSelected && !pressed)
                                ? AppShadow.card
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('EEE').format(day).toUpperCase(),
                                style: getMonoStyle(
                                  fontSize: 10.5,
                                  weight: FontWeightManager.bold,
                                  color: isSelected
                                      ? AppColors.onPrimary
                                      : AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${day.day}',
                                style: getMonoStyle(
                                  fontSize: 18,
                                  weight: FontWeightManager.extraBold,
                                  color: isSelected
                                      ? AppColors.onPrimary
                                      : AppColors.textColor,
                                ),
                              ),
                              if (units > 0) ...[
                                const SizedBox(height: 2),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentWarm
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
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

        // Main User Roster Cards List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.md,
              AppSpace.md,
              AppSpace.xl,
            ),
            children: [
              // const SizedBox(height: AppSpace.md),
              if (widget.vm.unsettledDayCount > 0) ...[
                UnsettledNotice(count: widget.vm.unsettledDayCount),
                const SizedBox(height: AppSpace.md),
              ],

              // Header for Selected Day
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat(
                      'EEEE, d MMMM',
                    ).format(selectedDate).toUpperCase(),
                    style: AppText.monoLabel.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    dayUnits > 0
                        ? '$dayUnits ${PackService.labels.unitCaps} TOTAL${dayCost > 0 ? " · ${PackService.currency.formatMajor(dayCost, decimals: false).toUpperCase()}" : ""}'
                        : 'NO ENTRIES',
                    style: AppText.monoLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),

              if (widget.vm.users.isEmpty)
                EmptyState(
                  svgAsset: Assets.svg.team.path,
                  title: 'No member entries',
                  message: 'No team members logged for this day.',
                )
              else
                ...widget.vm.users.map((u) {
                  final units = widget.vm.ledgerData[dateKey]?[u.uid] ?? 0;
                  final userCost = widget.vm.userCostOn(dateKey, u.uid);
                  final isMe = u.uid == widget.vm.currentUid;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: TactileContainer(
                      onTap: widget.vm.isAdmin
                          ? () {
                              EditUnitsDialog.show(
                                context,
                                userName: u.name,
                                photoUrl: u.photoUrl,
                                dateLabel: DateFormat(
                                  'EEE, d MMM',
                                ).format(selectedDate),
                                currentCount: units,
                                onSave: (newCount) async {
                                  await withLoadingOverlay(
                                    context,
                                    () => widget.vm.updateUnits(
                                      dateKey,
                                      u.uid,
                                      u.name,
                                      newCount,
                                    ),
                                  );
                                },
                              );
                            }
                          : null,
                      builder: (context, pressed) => Container(
                        padding: const EdgeInsets.all(AppSpace.md),
                        decoration: AppDecor.card(
                          color: isMe
                              ? AppColors.primarySoft
                              : AppColors.surface,
                          radius: AppRadius.md,
                          shadow: !pressed,
                        ),
                        child: Row(
                          children: [
                            UserAvatar(name: u.name, photoUrl: u.photoUrl),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMe ? '${u.name} (You)' : u.name,
                                    style: getBoldStyle(
                                      fontSize: 15,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$units ${PackService.labels.unitCaps}${userCost > 0 ? " · ${PackService.currency.formatMajor(userCost, decimals: false).toUpperCase()}" : ""}',
                                    style: AppText.monoLabel.copyWith(
                                      color: units > 0
                                          ? AppColors.primary
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Roti quantity badge matching the mockup design
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.md - 2,
                                vertical: AppSpace.xs + 2,
                              ),
                              decoration: BoxDecoration(
                                color: units > 0
                                    ? AppColors.accentWarm
                                    : AppColors.surfaceAlt,
                                borderRadius: AppRadius.rSm,
                                border: Border.all(
                                  color: units > 0
                                      ? AppColors.accentWarm
                                      : AppColors.border,
                                  width: AppDecor.strokeWidth,
                                ),
                                boxShadow: units > 0 ? AppShadow.card : null,
                              ),
                              child: Text(
                                '$units',
                                style: getMonoStyle(
                                  fontSize: 17,
                                  weight: FontWeightManager.extraBold,
                                  color: units > 0
                                      ? AppColors.textOnBrand
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: AppSpace.md),

              if (widget.vm.isAdmin) _buildSettleButton(context),
            ],
          ),
        ),
      ],
    );
  }
}
