import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/user_avatar.dart';
import '/features/dashboard/dashboard_viewmodel.dart';

/// Who you are, across the top of the drawer. The whole block is one tap
/// target that opens your profile, rather than two small buttons for the
/// photo and the name.
class DrawerProfileHeader extends StatefulWidget {
  final DashboardViewModel viewModel;
  final VoidCallback onTap;

  const DrawerProfileHeader({
    super.key,
    required this.viewModel,
    required this.onTap,
  });

  @override
  State<DrawerProfileHeader> createState() => _DrawerProfileHeaderState();
}

class _DrawerProfileHeaderState extends State<DrawerProfileHeader> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final name = viewModel.currentUserName.isNotEmpty
        ? viewModel.currentUserName
        : '${PackService.labels.activityName} user';
    // The brand colour runs up under the status bar instead of stopping
    // short of it.
    final topInset = MediaQuery.paddingOf(context).top;

    return Semantics(
      button: true,
      label: 'Edit profile',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            AppSpace.lg,
            topInset + AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
          ),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.primary : AppColors.primaryDeep,
            border: Border(
              bottom: BorderSide(
                color: AppColors.ink,
                width: AppDecor.strokeWidth,
              ),
            ),
          ),
          child: Row(
            children: [
              UserAvatar(
                name: name,
                photoUrl: viewModel.currentUserPhotoUrl,
                size: 56,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getExtraBoldStyle(
                        color: AppColors.textOnBrand,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      viewModel.isAdmin ? 'ADMIN' : 'MEMBER',
                      style: getMonoStyle(
                        fontSize: 10.5,
                        color: AppColors.textOnBrandMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Icon(
                Icons.edit_rounded,
                size: 18,
                color: AppColors.textOnBrandMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
