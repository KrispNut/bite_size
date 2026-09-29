import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/widgets/custom_button.dart';
import '/core/widgets/custom_dropdown_field.dart';
import '/core/widgets/user_avatar.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

class EditUnitsDialog extends StatefulWidget {
  final String userName;
  final String? photoUrl;
  final String dateLabel;
  final int currentCount;
  final ValueChanged<int> onSave;

  const EditUnitsDialog({
    super.key,
    required this.userName,
    this.photoUrl,
    required this.dateLabel,
    required this.currentCount,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String userName,
    String? photoUrl,
    required String dateLabel,
    required int currentCount,
    required ValueChanged<int> onSave,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => EditUnitsDialog(
        userName: userName,
        photoUrl: photoUrl,
        dateLabel: dateLabel,
        currentCount: currentCount,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditUnitsDialog> createState() => _EditUnitsDialogState();
}

class _EditUnitsDialogState extends State<EditUnitsDialog> {
  late int _selectedCount;

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.currentCount;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: AppDecor.card(radius: AppRadius.lg),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit ${PackService.labels.unit} count', style: AppText.h3),
            const SizedBox(height: AppSpace.md),
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: AppDecor.well(),
              child: Row(
                children: [
                  UserAvatar(
                    name: widget.userName,
                    photoUrl: widget.photoUrl,
                    size: 44,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.userName, style: AppText.titleMd),
                        const SizedBox(height: 3),
                        Text(
                          widget.dateLabel.toUpperCase(),
                          style: AppText.monoLabel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            CustomDropdownField(
              title: false,
              value: _selectedCount.toString(),
              hintText: 'Select ${PackService.labels.unitPlural}',
              items: List.generate(11, (index) => index.toString()),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCount = int.parse(value);
                  });
                }
              },
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPress: () => Navigator.of(context).pop(),
                    text: 'Cancel',
                    btnColor: AppColors.transparent,
                    textColor: AppColors.textSecondary,
                    isIcon: false,
                    elevated: false,
                    height: 46,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: CustomButton(
                    onPress: () {
                      Navigator.of(context).pop();
                      widget.onSave(_selectedCount);
                    },
                    text: 'Save',
                    btnColor: AppColors.primaryDeep,
                    textColor: AppColors.textOnBrand,
                    isIcon: false,
                    elevated: false,
                    height: 46,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
