import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '/core/alerts/app_alerts.dart';
import '/core/alerts/app_dialogs.dart';
import '/core/shared/custom_button.dart';
import '/core/shared/custom_textfield.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/features/auth/auth_view.dart';
import '/features/auth/auth_viewmodel.dart';
import '/features/chef_ai/widgets/ai_recipe_sheet.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import '/features/roti_ledger/roti_ledger_view.dart';
import 'settle_bill_sheet.dart';

/// App drawer: profile, the day's money actions, and sign out.
class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({super.key});

  void _pickAvatarImage(BuildContext context, DashboardViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) {
        Future<void> pick(
          ImageSource source,
          String opening,
          String done,
        ) async {
          Navigator.of(ctx).pop();
          ShowToastDialog.showLoader(opening);
          final err = await vm.uploadAndSetAvatar(source);
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(err ?? done);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                Text('Change profile photo', style: AppText.h3),
                const SizedBox(height: AppSpace.md),
                _SheetOption(
                  icon: Icons.camera_alt_rounded,
                  color: AppColors.info,
                  title: 'Take a photo',
                  subtitle: 'Use the camera',
                  onTap: () => pick(
                    ImageSource.camera,
                    'Opening camera...',
                    'Profile photo updated! 📸',
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                _SheetOption(
                  icon: Icons.photo_library_rounded,
                  color: AppColors.success,
                  title: 'Choose from gallery',
                  subtitle: 'Pick an existing image',
                  onTap: () => pick(
                    ImageSource.gallery,
                    'Opening gallery...',
                    'Profile photo updated! 🖼️',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, DashboardViewModel vm) {
    final nameCtrl = TextEditingController(text: vm.currentUserName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpace.lg,
            right: AppSpace.lg,
            top: AppSpace.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Text('Edit display name', style: AppText.h3),
              const SizedBox(height: 4),
              Text(
                'This is how you appear on today\'s roster.',
                style: AppText.bodySm,
              ),
              const SizedBox(height: AppSpace.lg),
              CustomTextField(
                context: ctx,
                controller: nameCtrl,
                label: 'Display name',
                hintText: 'Your full name',
                type: TextInputType.name,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpace.xl),
              CustomButton(
                onPress: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  Navigator.of(ctx).pop();
                  ShowToastDialog.showLoader('Saving name...');
                  final err = await vm.updateProfile(
                    name: name,
                    photoUrl: vm.currentUserPhotoUrl.isNotEmpty
                        ? vm.currentUserPhotoUrl
                        : null,
                  );
                  ShowToastDialog.closeLoader();
                  ShowToastDialog.showToast(err ?? 'Name updated! ✨');
                },
                text: 'Save name',
                btnColor: AppColors.primary,
                textColor: AppColors.onPrimary,
                isIcon: false,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final session = vm.session;
    final isSettled = session?.status.name == 'settled';

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.7),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _ProfileHeader(
                    vm: vm,
                    onAvatarTap: () => _pickAvatarImage(context, vm),
                    onEditTap: () => _showEditProfileDialog(context, vm),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.sm,
                        AppSpace.md,
                        AppSpace.sm,
                        AppSpace.md,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpace.md,
                            bottom: AppSpace.xs,
                          ),
                          child: Text('TODAY', style: getBoldStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ),
                        if (vm.isAdmin) ...[
                          _DrawerTile(
                            icon: Icons.receipt_long_rounded,
                            accent: isSettled ? AppColors.success : AppColors.textColor,
                            title: isSettled ? 'Bill settled' : 'Settle today\'s bill',
                            subtitle: isSettled
                                ? 'Total Rs ${(session?.totalRotiCost ?? 0).toInt()}'
                                : 'Enter roti cost & extra salan',
                            trailing: isSettled
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).pop();
                              SettleBillSheet.show(context);
                            },
                          ),
                          const SizedBox(height: AppSpace.xs),
                          _DrawerTile(
                            icon: Icons.delete_forever_rounded,
                            accent: AppColors.danger,
                            title: 'Reset today\'s data',
                            subtitle: 'Wipe all entries and session data for today',
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text('Reset Data?', style: getBoldStyle(color: AppColors.textColor, fontSize: 18)),
                                  content: Text(
                                    'This will permanently delete all entries and the session for today. Are you sure?',
                                    style: getMediumStyle(color: AppColors.textSecondary, fontSize: 14),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: Text('Cancel', style: getSemiBoldStyle(color: AppColors.textSecondary)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      child: Text('Reset', style: getBoldStyle(color: AppColors.danger)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                await withLoadingOverlay(context, () => vm.resetTodayData());
                                if (context.mounted) {
                                  Navigator.of(context).pop(); // Close the drawer
                                }
                              }
                            },
                          ),
                          const SizedBox(height: AppSpace.xs),
                        ],
                        const SizedBox(height: AppSpace.xs),
                        _DrawerTile(
                          icon: Icons.auto_awesome_rounded,
                          accent: AppColors.primary,
                          title: 'AI lunch assessment',
                          subtitle: 'Is there enough food for everyone?',
                          onTap: () {
                            Navigator.of(context).pop();
                            AiRecipeSheet.show(context);
                          },
                        ),
                        const SizedBox(height: AppSpace.xs),
                        _DrawerTile(
                          icon: Icons.menu_book_rounded,
                          accent: AppColors.textColor,
                          title: 'Roti Ledger',
                          subtitle: 'Monthly roti history for everyone',
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RotiLedgerView(),
                              ),
                            );
                          },
                        ),
                        if (vm.transactions.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.xl),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpace.md,
                              bottom: AppSpace.sm,
                            ),
                            child: Text('RECENT TRANSACTIONS', style: getBoldStyle(color: AppColors.textTertiary, fontSize: 11)),
                          ),
                          for (final tx in vm.transactions)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tx.fromId == vm.currentUid ? AppColors.danger : AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: Text(
                                      tx.fromId == vm.currentUid
                                          ? '${tx.fromName} · you'
                                          : tx.fromName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: getMediumStyle(
                                        fontSize: 14,
                                        color: AppColors.textColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Rs ${tx.amount.toInt()}',
                                    style: getExtraBoldStyle(
                                      fontSize: 14,
                                      color: tx.fromId == vm.currentUid
                                          ? AppColors.danger
                                          : AppColors.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.sm,
                0,
                AppSpace.sm,
                AppSpace.sm,
              ),
              child: _DrawerTile(
                icon: Icons.logout_rounded,
                accent: AppColors.danger,
                title: 'Sign out',
                onTap: () {
                  showCustomConfirmationDialog(
                    context,
                    'Sign out',
                    'You\'ll need to sign in again to see today\'s roster.',
                    () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      withLoadingOverlay(context, () async {
                        await context.read<AuthViewModel>().signOut();
                        appNavigatorKey.currentState?.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AuthView()),
                          (route) => false,
                        );
                      });
                    },
                    true,
                    icon: Icons.logout_rounded,
                    accentColor: AppColors.danger,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
);
}
}

class _ProfileHeader extends StatelessWidget {
  final DashboardViewModel vm;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditTap;

  const _ProfileHeader({
    required this.vm,
    required this.onAvatarTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = vm.currentUserPhotoUrl;
    final name = vm.currentUserName.isNotEmpty
        ? vm.currentUserName
        : 'Bite Size user';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceAlt,
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    image: photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: photoUrl.isNotEmpty
                      ? null
                      : Text(
                          name[0].toUpperCase(),
                          style: getExtraBoldStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                          ),
                        ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.textSecondary,
                      size: 11,
                    ),
                  ),
                ),
              ],
            ),
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
                  style: getExtraBoldStyle(color: AppColors.textColor, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap the avatar to change',
                  style: getMediumStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onEditTap,
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData? icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DrawerTile({
    this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.rSm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs,
            vertical: AppSpace.xs + 2,
          ),
          child: Row(
            children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 22),
                ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppText.titleMd),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: AppRadius.rSm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.rSm,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppText.titleMd),
                    const SizedBox(height: 1),
                    Text(subtitle, style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
