import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/core/services/sound_service.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/sheet_handle.dart';

/// Modal bottom sheet allowing 1-tap selection of past months and years.
class MonthPickerSheet extends StatelessWidget {
  final DateTime currentMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const MonthPickerSheet({
    super.key,
    required this.currentMonth,
    required this.onMonthSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime currentMonth,
    required ValueChanged<DateTime> onMonthSelected,
  }) async {
    SoundService.instance.playTapSound();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (context) => MonthPickerSheet(
        currentMonth: currentMonth,
        onMonthSelected: onMonthSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Build list of months for the past 24 months up to current month
    final months = <DateTime>[];
    for (int i = 0; i < 24; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      months.add(month);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetHandle()),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpace.xs),
                Text('Select Month', style: AppText.h2),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: months.map((m) {
                    final isSelected =
                        m.year == currentMonth.year &&
                        m.month == currentMonth.month;
                    final label = DateFormat('MMM yyyy').format(m);

                    return GestureDetector(
                      onTap: () {
                        SoundService.instance.playTapSound();
                        onMonthSelected(m);
                        Navigator.of(context).pop();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceAlt,
                          borderRadius: AppRadius.rSm,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: AppDecor.strokeWidth,
                          ),
                          boxShadow: isSelected ? AppShadow.card : null,
                        ),
                        child: Text(
                          label,
                          style: getSemiBoldStyle(
                            fontSize: 13.5,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.textColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
