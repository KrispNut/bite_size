import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/custom_button.dart';
import '/features/dashboard/models/shared_expense.dart';

class InviteRow extends StatelessWidget {
  final SharedExpense expense;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const InviteRow({
    super.key,
    required this.expense,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final currency = PackService.currency;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.xs),
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: AppDecor.card(radius: AppRadius.sm, shadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expense.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getBoldStyle(
                        color: AppColors.textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.paidByName} paid '
                      '${currency.format(expense.costMinor, decimals: false)} · '
                      'asked ${expense.invitedCount} '
                      '${expense.invitedCount == 1 ? 'person' : 'people'}',
                      style: AppText.caption,
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
                    '~${currency.format(expense.estimatedShareMinor, decimals: false)}',
                    style: getExtraBoldStyle(
                      color: AppColors.accentWarm,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'your share',
                    style: getMediumStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPress: onDecline,
                  text: 'Not me',
                  btnColor: AppColors.transparent,
                  textColor: AppColors.textSecondary,
                  borderColor: AppColors.border,
                  isIcon: false,
                  elevated: false,
                  height: 40,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                flex: 2,
                child: CustomButton(
                  onPress: onAccept,
                  text: 'Count me in',
                  btnColor: AppColors.primary,
                  textColor: AppColors.onPrimary,
                  isIcon: true,
                  iconData: Icons.check_rounded,
                  iconColor: AppColors.onPrimary,
                  elevated: false,
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
