import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// Labelled text field used across the forms and sheets.
///
/// Styling comes from `inputDecorationTheme`; this widget adds the label row,
/// the focus ring and the optional helper line on top of it.
class CustomTextField extends StatefulWidget {
  final bool obscureText;
  final String? Function(String?)? validatorFn;
  final BuildContext context;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType type;
  final TextInputAction textInputAction;
  final TextEditingController controller;
  final Widget? suf;
  final Widget? prefix;
  final bool enabled;
  final bool isMap;
  final int minLines;
  final int maxLines;
  final FocusNode? focusNode;
  final String hintText;

  /// Shows the label row above the field. Falls back to [hintText] when no
  /// explicit [label] is given.
  final bool title;
  final String? label;
  final String? helperText;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final InputDecoration? decoration;
  final bool hasError;

  const CustomTextField({
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
    this.suf,
    this.obscureText = false,
    this.isMap = false,
    this.enabled = true,
    required this.hintText,
    this.prefix,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.decoration,
    this.hasError = false,
    this.label,
    this.helperText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _ownsFocusNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelText = widget.label ?? widget.hintText;
    final accent = widget.hasError ? AppColors.danger : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title) ...[
          Text(
            labelText,
            style: getSemiBoldStyle(
              fontSize: 12.5,
              color: _focused ? accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
        ],
        TapRegion(
          onTapOutside: (_) {
            if (_focusNode.hasFocus) {
              _focusNode.unfocus();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rSm,
              // Inputs sit recessed at rest and lift onto a hard offset when
              // focused — the inverse of a button, which starts lifted.
              boxShadow: _focused ? AppShadow.card : null,
            ),
            child: TextFormField(
              focusNode: _focusNode,
              minLines: widget.obscureText ? 1 : widget.minLines,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              enabled: widget.enabled,
              validator: widget.validatorFn,
              obscureText: widget.obscureText,
              onFieldSubmitted: widget.onFieldSubmitted,
              onChanged: widget.onChanged,
              controller: widget.controller,
              cursorErrorColor: AppColors.danger,
              textInputAction: widget.textInputAction,
              keyboardType: widget.type,
              inputFormatters: widget.inputFormatters,
              style: getMediumStyle(fontSize: 14.5, color: AppColors.textColor),
              cursorColor: AppColors.primary,
              cursorRadius: const Radius.circular(2),
              decoration: widget.decoration ?? _decoration(),
            ),
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(widget.helperText!, style: AppText.caption),
        ],
      ],
    );
  }

  InputDecoration _decoration() {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.rSm,
          borderSide: BorderSide(color: color, width: width),
        );

    final idle = widget.hasError
        ? AppColors.danger
        : AppColors.textFieldBorderColor;

    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: getRegularStyle(
        fontSize: 14,
        color: widget.isMap
            ? AppColors.textColor
            : AppColors.textFieldPlaceholderColor,
      ),
      filled: true,
      fillColor: widget.enabled
          ? AppColors.textFieldFillColor
          : AppColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm + 2,
        vertical: AppSpace.sm + 2,
      ),
      border: border(idle),
      enabledBorder: border(idle),
      focusedBorder: border(
        widget.hasError ? AppColors.danger : AppColors.primary,
        1.5,
      ),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.5),
      disabledBorder: border(AppColors.border),
      errorStyle: getMediumStyle(fontSize: 11.5, color: AppColors.danger),
      suffixIcon: widget.suf,
      prefixIcon: widget.prefix,
      // Material reserves a 48pt square for prefixes; text affixes like a currency symbol
      // need to hug their content instead.
      prefixIconConstraints: widget.prefix == null
          ? null
          : const BoxConstraints(minWidth: 0, minHeight: 0),
      prefixIconColor: _focused ? AppColors.primary : AppColors.textTertiary,
      suffixIconColor: _focused ? AppColors.primary : AppColors.textTertiary,
    );
  }
}
