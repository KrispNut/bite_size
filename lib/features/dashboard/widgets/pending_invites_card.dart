import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/widgets/app_icon.dart';
import '/core/alerts/dialogs.dart';
import '/core/alerts/toast.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import '/features/dashboard/models/shared_expense.dart';
import 'invite_row.dart';
import '/generated/assets.dart';

class PendingInvitesCard extends StatelessWidget {
  final DashboardViewModel viewModel;

  const PendingInvitesCard({super.key, required this.viewModel});

  Future<void> _respond(
    BuildContext context,
    SharedExpense expense,
    bool accept,
  ) async {
    Future<void> send() => ShowToastDialog.whileLoading(
      accept ? 'Joining in...' : 'Backing out...',
      () => viewModel.respondToExpense(expense.id, accept: accept),
      success: accept
          ? 'You\'re in on ${expense.description} ✅'
          : 'Left out of ${expense.description}',
    );

    if (accept) {
      await send();
      return;
    }

    showCustomConfirmationDialog(
      context,
      'Not joining?',
      '"${expense.description}" will be split between the others instead, '
          'and their share goes up.',
      () {
        Navigator.of(context).pop();
        send();
      },
      true,
      accentColor: AppColors.warning,
      confirmLabel: 'I\'m out',
      cancelLabel: 'Go back',
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = PackService.labels;
    final invites = viewModel.myPendingInvites;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecor.tinted(AppColors.accentWarm, shadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: AppDecor.filled(
                  AppColors.accentFill,
                  radius: AppRadius.xs,
                ),
                child: AppIcon(Assets.svg.plate.path, size: 18),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  invites.length == 1
                      ? 'A ${labels.expense} needs your answer'
                      : '${invites.length} ${labels.expensePlural} need '
                            'your answer',
                  style: getExtraBoldStyle(
                    color: AppColors.textColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Nobody can set off on the ${labels.errand} until you reply.',
            style: AppText.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          for (final expense in invites)
            InviteRow(
              expense: expense,
              onAccept: () => _respond(context, expense, true),
              onDecline: () => _respond(context, expense, false),
            ),
        ],
      ),
    );
  }
}
