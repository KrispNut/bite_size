import '/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '/core/theme/textfont_styles.dart';

Widget reusableCheckBox({
  required String title,
  required String secondaryText,
  required bool? value,
  required void Function(bool?)? onChanged,
}) {
  final bool isSelected = value ?? false;

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
        onTap: onChanged == null ? null : () => onChanged(!isSelected),
        splashColor: AppColors.splashColor1,
        highlightColor: AppColors.splashColor1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                splashRadius: 0,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                checkColor: AppColors.checkboxTickColor,
                activeColor: AppColors.tertiary,
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.checkboxSelectedBgColor;
                  }
                  return AppColors.transparent;
                }),
                side: BorderSide(color: AppColors.borderColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
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
