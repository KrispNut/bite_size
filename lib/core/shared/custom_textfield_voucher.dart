import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/textfont_styles.dart';

class VoucherTextField extends StatelessWidget {
  final bool obscureText;
  final String? Function(String?)? validatorFn;
  final BuildContext context;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType type;
  final TextInputAction textInputAction;
  final TextEditingController controller;
  final Widget? leftWidget; // 👈 Added for left-side widget
  final bool enabled;
  final int minLines;
  final int maxLines;
  final FocusNode? focusNode;
  final String hintText;
  final bool title;
  final void Function(String)? onChanged;

  const VoucherTextField({
    super.key,
    this.validatorFn,
    this.minLines = 1,
    this.maxLines = 1,
    this.title = true,
    required this.context,
    this.inputFormatters,
    required this.type,
    required this.textInputAction,
    required this.controller,
    this.obscureText = false,
    this.enabled = true,
    required this.hintText,
    this.onChanged,
    this.focusNode,
    this.leftWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              hintText,
              style: getSemiBoldStyle(color: AppColors.textColor, fontSize: 12),
            ),
          ),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (leftWidget != null) ...[
                leftWidget!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextFormField(
                  focusNode: focusNode,
                  minLines: obscureText ? 1 : minLines,
                  maxLines: obscureText ? 1 : maxLines,
                  enabled: enabled,
                  validator: validatorFn,
                  obscureText: obscureText,
                  controller: controller,
                  textInputAction: textInputAction,
                  keyboardType: type,
                  inputFormatters: inputFormatters,
                  style: getRegularStyle(
                    fontSize: 14,
                    color: AppColors.textColor,
                  ),
                  cursorColor: AppColors.textFieldCursorColor,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: getRegularStyle(
                      fontSize: 14,
                      color: AppColors.textFieldPlaceholderColor,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
