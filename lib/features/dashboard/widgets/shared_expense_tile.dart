import 'package:flutter/material.dart';
import '/core/alerts/dialogs.dart';
import '/core/alerts/toast.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/icon_button.dart';
import '/core/widgets/pill.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import '/features/dashboard/models/shared_expense.dart';
import '/generated/assets.dart';

class SharedExpenseTile extends StatelessWidget {
  final SharedExpense expense;
  final DashboardViewModel viewModel;

  const SharedExpenseTile({
    super.key,
    required this.expense,
    required this.viewModel,
  });

  static (IconData, Color) _answerIcon(ExpenseShare share) {
    if (share.isAccepted) {
      return (Icons.check_circle_rounded, AppColors.success);
    }
    if (share.isDeclined) {
      return (Icons.cancel_rounded, AppColors.textTertiary);
    }
    return (Icons.schedule_rounded, AppColors.warning);
  }

  void _confirmRemove(BuildContext context) {
    showCustomConfirmationDialog(
      context,
      'Remove this ${PackService.labels.expense}?',
      '"${expense.description}" will be dropped from the bill.',
      () {
        Navigator.of(context).pop();
        ShowToastDialog.whileLoading(
          'Removing...',
          () => viewModel.removeSharedExpense(expense.id),
        );
      },
      true,
      confirmLabel: 'Remove',
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = viewModel.currentUid;
    final myShare = expense.shareFor(me);
    final iPaid = expense.paidById == me;
    final iAmIn = myShare?.isAccepted ?? false;
    final awaitingMe = expense.awaitsResponseFrom(me);
    final departed = viewModel.session?.hasDeparted ?? false;
    final canRemove = (iPaid || viewModel.isAdmin) && !departed;
    final cost = PackService.currency.formatMajor(
      expense.cost,
      decimals: false,
    );

    final accent = expense.isCancelled
        ? AppColors.textTertiary
        : expense.isPending
        ? AppColors.warning
        : AppColors.accentWarm;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.sm + 2),
      decoration: AppDecor.card(
        color: awaitingMe ? AppColors.tint(accent, 0.12) : AppColors.surface,
        radius: AppRadius.md,
        shadow: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.tint(accent, 0.24),
                  borderRadius: AppRadius.rXs,
                  border: Border.all(color: AppColors.ink),
                ),
                alignment: Alignment.center,
                child: AppIcon(Assets.svg.plate.path, size: 19),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            expense.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: getBoldStyle(
                              color: expense.isCancelled
                                  ? AppColors.textTertiary
                                  : AppColors.textColor,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        if (expense.isPending) ...[
                          const SizedBox(width: AppSpace.xs),
                          Pill(
                            label: 'Waiting on ${expense.pendingCount}',
                            color: AppColors.warning,
                          ),
                        ] else if (expense.isCancelled) ...[
                          const SizedBox(width: AppSpace.xs),
                          Pill(
                            label: 'Nobody joined',
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      iPaid
                          ? 'You paid $cost'
                          : '${expense.paidByName} paid $cost',
                      style: getMediumStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    iAmIn
                        ? PackService.currency.formatMajor(
                            myShare!.amount,
                            decimals: false,
                          )
                        : '—',
                    style: getExtraBoldStyle(
                      color: iAmIn ? accent : AppColors.textTertiary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    awaitingMe
                        ? 'your call'
                        : iAmIn
                        ? 'your share'
                        : myShare == null
                        ? 'not you'
                        : 'you passed',
                    style: getMediumStyle(
                      color: awaitingMe
                          ? AppColors.warning
                          : AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  if (canRemove) ...[
                    const SizedBox(height: 2),
                    AppIconButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: () => _confirmRemove(context),
                      size: 15,
                      color: AppColors.danger,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final share in expense.shares) _buildPersonChip(share, me),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonChip(ExpenseShare share, String me) {
    final (icon, color) = _answerIcon(share);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: AppDecor.pill(color, alpha: 0.18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            share.userId == me ? 'You' : share.userName.split(' ').first,
            style: getMediumStyle(
              color: share.isAccepted
                  ? AppColors.textColor
                  : AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
