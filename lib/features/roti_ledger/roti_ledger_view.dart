import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '/core/alerts/app_dialogs.dart';
import '/core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/textfont_styles.dart';
import 'roti_ledger_viewmodel.dart';
import 'widgets/edit_roti_dialog.dart';

/// Full-month Roti Ledger: a scrollable table showing everyone's daily roti
/// orders, with weekend exclusion and admin-only editing.
class RotiLedgerView extends StatelessWidget {
  const RotiLedgerView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RotiLedgerViewModel()..loadMonth(),
      child: const _RotiLedgerBody(),
    );
  }
}

class _RotiLedgerBody extends StatelessWidget {
  const _RotiLedgerBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RotiLedgerViewModel>();

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Roti Ledger',
          style: getBoldStyle(color: AppColors.textColor, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Month Navigation Bar ──
          _MonthNavBar(vm: vm),

          // ── Content ──
          Expanded(
            child: vm.error != null && !vm.isLoading
                ? _ErrorWidget(message: vm.error!, onRetry: vm.loadMonth)
                : Skeletonizer(
                    enabled: vm.isLoading,
                    enableSwitchAnimation: true,
                    child: vm.users.isEmpty && !vm.isLoading
                        ? _EmptyState()
                        : _LedgerTable(vm: vm),
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MONTH NAVIGATION BAR
// =============================================================================

class _MonthNavBar extends StatelessWidget {
  final RotiLedgerViewModel vm;
  const _MonthNavBar({required this.vm});

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
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: vm.goToPreviousMonth,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
            ),
          ),
          Column(
            children: [
              Text(
                vm.monthLabel,
                style: getBoldStyle(color: AppColors.textColor, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                '${vm.workingDays.length} working days · ${vm.grandTotalRotis} rotis total',
                style: getRegularStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: isCurrentMonth ? null : vm.goToNextMonth,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isCurrentMonth
                  ? AppColors.textTertiary
                  : AppColors.textColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LEDGER TABLE
// =============================================================================

class _LedgerTable extends StatelessWidget {
  final RotiLedgerViewModel vm;
  const _LedgerTable({required this.vm});

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final days = vm.workingDays;
    final users = vm.users;

    if (days.isEmpty || users.isEmpty) {
      return _EmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpace.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamic width calculation so it stretches when few users
          final fixedColsWidth = 60.0 + 50.0;
          final margins = 24.0 + (14.0 * (users.length + 1));
          final availableWidth = constraints.maxWidth - fixedColsWidth - margins;
          final userColWidth = users.isEmpty ? 64.0 : (availableWidth / users.length).clamp(64.0, double.infinity);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: AppRadius.rSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: DataTable(
                    columnSpacing: 14,
                    horizontalMargin: 12,
                    headingRowHeight: 52,
                    dataRowMinHeight: 42,
                    dataRowMaxHeight: 42,
                    headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
                    border: TableBorder(
                      horizontalInside: BorderSide(color: AppColors.border),
                      verticalInside: BorderSide(color: AppColors.border),
                    ),
                    columns: [
            DataColumn(
              label: Text(
                'Date',
                style: getBoldStyle(
                  color: AppColors.textColor,
                  fontSize: 12,
                ),
              ),
            ),
            ...users.map(
              (u) => DataColumn(
                label: SizedBox(
                  width: userColWidth,
                  child: Text(
                    u.name.split(' ').first,
                    style: getBoldStyle(
                      color: AppColors.textColor,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Total',
                style: getBoldStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          rows: [
            // ── Data rows (one per working day) ──
            ...days.map((day) {
              final dateKey = _dateStr(day);
              final dayLabel = DateFormat('EEE, d MMM').format(day);
              final isToday = _dateStr(DateTime.now()) == dateKey;
              final dayTotal = vm.dayTotalRotis(dateKey);

              return DataRow(
                color: isToday
                    ? WidgetStateProperty.all(
                        AppColors.primarySoft,
                      )
                    : null,
                cells: [
                  DataCell(
                    Text(
                      dayLabel,
                      style: getSemiBoldStyle(
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  ...users.map((u) {
                    final rotis =
                        vm.ledgerData[dateKey]?[u.uid] ?? 0;
                    final hasEntry =
                        vm.ledgerData[dateKey]?.containsKey(u.uid) ?? false;

                    return DataCell(
                      InkWell(
                        onTap: vm.isAdmin
                            ? () {
                                HapticFeedback.selectionClick();
                                EditRotiDialog.show(
                                  context,
                                  userName: u.name,
                                  photoUrl: u.photoUrl,
                                  dateLabel: dayLabel,
                                  currentCount: rotis,
                                  onSave: (newCount) async {
                                    await withLoadingOverlay(
                                      context,
                                      () => vm.updateRotis(
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
                        child: Center(
                          child: Text(
                            hasEntry ? '$rotis' : '—',
                            style: getMediumStyle(
                              color: hasEntry
                                  ? (rotis > 0
                                      ? AppColors.textColor
                                      : AppColors.textTertiary)
                                  : AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  DataCell(
                    Center(
                      child: Text(
                        '$dayTotal',
                        style: getBoldStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            // ── Totals row ──
            DataRow(
              color: WidgetStateProperty.all(AppColors.surfaceAlt),
              cells: [
                DataCell(
                  Text(
                    'TOTAL',
                    style: getExtraBoldStyle(
                      color: AppColors.textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
                ...users.map((u) {
                  final total = vm.userTotalRotis(u.uid);
                  return DataCell(
                    Center(
                      child: Text(
                        '$total',
                        style: getExtraBoldStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
                DataCell(
                  Center(
                    child: Text(
                      '${vm.grandTotalRotis}',
                      style: getExtraBoldStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
        },
      ),
    );
  }
}

// =============================================================================
// EMPTY + ERROR STATES
// =============================================================================

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: AppSpace.md),
          Text(
            'No roti records yet',
            style: getBoldStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Records will appear as team members\nlog their daily entries.',
            textAlign: TextAlign.center,
            style: getRegularStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpace.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: AppSpace.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: getMediumStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSpace.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
