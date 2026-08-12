// ignore_for_file: deprecated_member_use

import '/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '/core/theme/textfont_styles.dart';

Widget reusableRadioButton({
  required String title,
  required String secondaryText,
  required var value,
  required var groupValue,
  bool toggleable = true,
  required void Function(dynamic)? onChanged,
}) {
  final bool isSelected = value == groupValue;

  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: AppColors.containerColor1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.borderColor, width: .25),
      ),
      child: InkWell(
        onTap: onChanged == null
            ? null
            : () {
                if (toggleable && isSelected) {
                  onChanged(null);
                } else {
                  onChanged(value);
                }
              },
        splashColor: AppColors.splashColor1,
        highlightColor: AppColors.splashColor1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          child: Row(
            children: [
              Radio<dynamic>(
                value: value,
                groupValue: groupValue,
                onChanged: null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                splashRadius: 0,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                activeColor: AppColors.radioSelectedColor,
              ),
              Expanded(
                child: Text(
                  title,
                  style: getRegularStyle(
                    color: AppColors.textColor,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                secondaryText,
                style: getSemiBoldStyle(
                  color: AppColors.textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
