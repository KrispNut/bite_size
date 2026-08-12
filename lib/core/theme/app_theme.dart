import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';
import 'textfont_styles.dart';

/// Builds the Material [ThemeData] from the Bite Size design tokens.
///
/// Most widgets in this app read [AppColors] directly, but framework-owned
/// surfaces (dialogs, sheets, ripples, pickers, snackbars, scrollbars) only
/// obey [ThemeData] — so it has to be styled properly too, or Material's
/// defaults leak purple-ish `ColorScheme.fromSeed` colours into the UI.
class AppTheme {
  AppTheme._();

  static ThemeData get light =>
      AppColors.resolveFor(Brightness.light, () => _build(Brightness.light));

  static ThemeData get dark =>
      AppColors.resolveFor(Brightness.dark, () => _build(Brightness.dark));

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.accentWarm,
      onSecondary: AppColors.white,
      error: AppColors.danger,
      onError: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textColor,
      surfaceContainerHighest: AppColors.surfaceAlt,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderStrong,
    );

    final textTheme = TextTheme(
      displayLarge: AppText.display,
      headlineLarge: AppText.h1,
      headlineMedium: AppText.h2,
      headlineSmall: AppText.h3,
      titleLarge: AppText.h3,
      titleMedium: AppText.titleMd,
      titleSmall: AppText.titleSm,
      bodyLarge: AppText.bodyLg,
      bodyMedium: AppText.bodyMd,
      bodySmall: AppText.bodySm,
      labelLarge: AppText.label,
      labelMedium: AppText.caption,
      labelSmall: AppText.overline,
    );

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.rSm,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.bgColor,
      canvasColor: AppColors.bgColor,
      dividerColor: AppColors.divider,
      splashColor: AppColors.splashColor,
      highlightColor: AppColors.splashColor,
      iconTheme: IconThemeData(color: AppColors.iconColor, size: 22),
      primaryIconTheme: IconThemeData(color: AppColors.primary),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgColor,
        foregroundColor: AppColors.textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: AppColors.systemOverlayStyle,
        titleTextStyle: AppText.h2,
        iconTheme: IconThemeData(color: AppColors.textColor, size: 24),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rMd,
          side: BorderSide(color: AppColors.border),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        titleTextStyle: AppText.h3,
        contentTextStyle: AppText.bodyMd,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textColor,
        titleTextStyle: AppText.titleMd,
        subtitleTextStyle: AppText.bodySm,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.textFieldFillColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.sm + 2,
        ),
        hintStyle: getRegularStyle(
          fontSize: 14,
          color: AppColors.textFieldPlaceholderColor,
        ),
        labelStyle: AppText.label,
        errorStyle: getMediumStyle(fontSize: 12, color: AppColors.danger),
        border: fieldBorder(AppColors.textFieldBorderColor),
        enabledBorder: fieldBorder(AppColors.textFieldBorderColor),
        focusedBorder: fieldBorder(AppColors.primary, 1.5),
        errorBorder: fieldBorder(AppColors.danger),
        focusedErrorBorder: fieldBorder(AppColors.danger, 1.5),
        disabledBorder: fieldBorder(AppColors.border),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.btnDisabledColor,
          disabledForegroundColor: AppColors.btnDisabledTextColor,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
          textStyle: AppText.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textColor,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
          textStyle: getBoldStyle(fontSize: 15, color: AppColors.textColor),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: getBoldStyle(fontSize: 14, color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rXs),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textColor,
        contentTextStyle: getMediumStyle(
          fontSize: 13.5,
          color: AppColors.bgColor,
        ),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
        elevation: 0,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(AppColors.onPrimary),
        side: BorderSide(color: AppColors.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.borderStrong,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surfaceAlt,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primarySoft,
        side: BorderSide(color: AppColors.border),
        labelStyle: AppText.titleSm,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rPill),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textColor,
          borderRadius: AppRadius.rXs,
        ),
        textStyle: getMediumStyle(fontSize: 12, color: AppColors.bgColor),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
