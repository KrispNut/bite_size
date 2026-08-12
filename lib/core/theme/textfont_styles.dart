import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/fonts_manager.dart';

/// Optical defaults: larger type gets tighter tracking and leading, small type
/// gets a touch more of both. Applied centrally so every call site benefits.
double _trackingFor(double fontSize) {
  if (fontSize >= 40) return -1.6;
  if (fontSize >= 28) return -0.8;
  if (fontSize >= 20) return -0.4;
  if (fontSize >= 16) return -0.1;
  if (fontSize <= 11) return 0.3;
  return 0;
}

double _leadingFor(double fontSize) {
  if (fontSize >= 40) return 1.02;
  if (fontSize >= 28) return 1.12;
  if (fontSize >= 20) return 1.22;
  if (fontSize >= 16) return 1.32;
  return 1.38;
}

TextStyle _getTextStyle(
  double fontSize,
  FontWeight fontWeight,
  Color color, {
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing ?? _trackingFor(fontSize),
    height: height ?? _leadingFor(fontSize),
  );
}

TextStyle getRegularStyle({
  double fontSize = 16,
  required Color color,
  double? letterSpacing,
  double? height,
}) =>
    _getTextStyle(fontSize, FontWeightManager.regular, color,
        letterSpacing: letterSpacing, height: height);

TextStyle getMediumStyle({
  double fontSize = 16,
  required Color color,
  double? letterSpacing,
  double? height,
}) =>
    _getTextStyle(fontSize, FontWeightManager.medium, color,
        letterSpacing: letterSpacing, height: height);

TextStyle getLightStyle({
  double fontSize = 14,
  required Color color,
  double? letterSpacing,
  double? height,
}) =>
    _getTextStyle(fontSize, FontWeightManager.light, color,
        letterSpacing: letterSpacing, height: height);

TextStyle getBoldStyle({
  double fontSize = 14,
  required Color color,
  double? letterSpacing,
  double? height,
}) =>
    _getTextStyle(fontSize, FontWeightManager.bold, color,
        letterSpacing: letterSpacing, height: height);

TextStyle getSemiBoldStyle({
  double fontSize = 14,
  required Color color,
  double? letterSpacing,
  double? height,
}) =>
    _getTextStyle(fontSize, FontWeightManager.semiBold, color,
        letterSpacing: letterSpacing, height: height);

TextStyle getExtraBoldStyle({
  double fontSize = 14,
  required Color color,
  double? letterSpacing,
  double? height,
}) =>
    _getTextStyle(fontSize, FontWeightManager.extraBold, color,
        letterSpacing: letterSpacing, height: height);

/// Named type scale. Use these instead of hand-picking a size + weight so the
/// hierarchy stays consistent between screens.
///
/// ```dart
/// Text('Today\'s Roster', style: AppText.h3)
/// Text('12 rotis', style: AppText.bodySm.copyWith(color: AppColors.primary))
/// ```
class AppText {
  AppText._();

  /// Hero numerals only (the roti count).
  static TextStyle get display =>
      getExtraBoldStyle(fontSize: 56, color: AppColors.textColor);

  static TextStyle get h1 =>
      getExtraBoldStyle(fontSize: 30, color: AppColors.textColor);
  static TextStyle get h2 =>
      getExtraBoldStyle(fontSize: 22, color: AppColors.textColor);
  static TextStyle get h3 =>
      getBoldStyle(fontSize: 17, color: AppColors.textColor);

  /// Card titles / list item primary line.
  static TextStyle get titleMd =>
      getSemiBoldStyle(fontSize: 15, color: AppColors.textColor);
  static TextStyle get titleSm =>
      getSemiBoldStyle(fontSize: 13, color: AppColors.textColor);

  static TextStyle get bodyLg =>
      getRegularStyle(fontSize: 15, color: AppColors.textColor);
  static TextStyle get bodyMd =>
      getRegularStyle(fontSize: 13.5, color: AppColors.textColor);
  static TextStyle get bodySm =>
      getRegularStyle(fontSize: 12.5, color: AppColors.textSecondary);

  /// Field labels, section eyebrows.
  static TextStyle get label =>
      getSemiBoldStyle(fontSize: 12.5, color: AppColors.textSecondary);
  static TextStyle get caption =>
      getRegularStyle(fontSize: 11.5, color: AppColors.textTertiary);

  /// ALL-CAPS eyebrow above a section or inside a badge.
  static TextStyle get overline => getBoldStyle(
        fontSize: 11,
        color: AppColors.textTertiary,
        letterSpacing: 0.9,
      );

  static TextStyle get button =>
      getBoldStyle(fontSize: 15, color: AppColors.onPrimary);

  /// Tabular-ish numeric emphasis inside badges and stat pills.
  static TextStyle get numeric =>
      getExtraBoldStyle(fontSize: 16, color: AppColors.textColor);
}
