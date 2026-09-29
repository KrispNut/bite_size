import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/user_avatar.dart';
import '/features/auth/models/app_user.dart';

class SharePersonRow extends StatelessWidget {
  final AppUser user;
  final bool isMe;
  final bool selected;
  final int amountMinor;
  final VoidCallback onTap;

  const SharePersonRow({
    super.key,
    required this.user,
    required this.isMe,
    required this.selected,
    required this.amountMinor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs + 1,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 19,
              color: selected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpace.sm),
            UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 30),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                isMe ? '${user.name} (you)' : user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: getSemiBoldStyle(
                  fontSize: 13.5,
                  color: selected
                      ? AppColors.textColor
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (selected && amountMinor > 0)
              Text(
                '~${PackService.currency.format(amountMinor, decimals: false)}',
                style: getBoldStyle(
                  fontSize: 12.5,
                  color: AppColors.accentWarm,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
