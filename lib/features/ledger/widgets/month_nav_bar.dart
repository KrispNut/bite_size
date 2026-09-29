import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/icon_button.dart';
import '/features/ledger/ledger_viewmodel.dart';
import 'month_picker_sheet.dart';

/// Month stepper and view toggle above the ledger.
class MonthNavBar extends StatelessWidget {
  final LedgerViewModel vm;

  const MonthNavBar({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        vm.currentMonth.year == now.year && vm.currentMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: AppDecor.strokeWidth,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: vm.goToPreviousMonth,
              ),
              GestureDetector(
                onTap: () => MonthPickerSheet.show(
                  context,
                  currentMonth: vm.currentMonth,
                  onMonthSelected: vm.setMonth,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm + 2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: AppRadius.rSm,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(vm.monthLabel, style: AppText.h3),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              AppIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: isCurrentMonth ? null : vm.goToNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${vm.workingDays.length} DAYS · '
            '${vm.grandTotalUnits} ${PackService.labels.unitCaps}'
            '${vm.grandTotalCost > 0 ? ' · RS ${vm.grandTotalCost.round()}' : ''}',
            style: AppText.monoLabel,
          ),
        ],
      ),
    );
  }
}
