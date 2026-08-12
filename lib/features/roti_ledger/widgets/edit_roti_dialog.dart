import 'package:flutter/material.dart';
import '/core/shared/custom_dropdown_field.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';

class EditRotiDialog extends StatefulWidget {
  final String userName;
  final String? photoUrl;
  final String dateLabel;
  final int currentCount;
  final ValueChanged<int> onSave;

  const EditRotiDialog({
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
      builder: (context) => EditRotiDialog(
        userName: userName,
        photoUrl: photoUrl,
        dateLabel: dateLabel,
        currentCount: currentCount,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditRotiDialog> createState() => _EditRotiDialogState();
}

class _EditRotiDialogState extends State<EditRotiDialog> {
  late int _selectedCount;

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.currentCount;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Roti Count',
              style: getBoldStyle(color: AppColors.textColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySoft,
                    image: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: widget.photoUrl == null || widget.photoUrl!.isEmpty
                      ? Text(
                          widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                          style: getBoldStyle(color: AppColors.primary, fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.userName,
                        style: getBoldStyle(color: AppColors.textColor, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.dateLabel,
                        style: getMediumStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            CustomDropdownField(
              title: false,
              value: _selectedCount.toString(),
              hintText: 'Select rotis',
              items: List.generate(11, (index) => index.toString()),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCount = int.parse(value);
                  });
                }
              },
            ),
            const SizedBox(height: AppSpace.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: getMediumStyle(color: AppColors.textColor)),
                ),
                const SizedBox(width: AppSpace.md),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSave(_selectedCount);
                  },
                  child: Text('Save', style: getMediumStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
