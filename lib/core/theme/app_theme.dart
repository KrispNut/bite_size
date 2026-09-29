import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'activity_packs.dart';
import '/core/constants/app_constants.dart';
import 'text_styles.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  factory ThemeService() => instance;
  ThemeService._internal();

  ThemeMode themeMode = AppConstants.currentTheme ?? ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;

  void toggleTheme() {
    themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    AppConstants.currentTheme = themeMode;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    themeMode = mode;
    AppConstants.currentTheme = mode;
    notifyListeners();
  }
}

class AppRadius {
  AppRadius._();
  static double get _s => PackService.shape.radiusScale;
  static double get xs => 4 * _s;
  static double get sm => 8 * _s;
  static double get md => 12 * _s;
  static double get lg => 16 * _s;
  static double get xl => 24 * _s;
  static const double pill = 999;

  static BorderRadius get rXs => BorderRadius.circular(xs);
  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rPill => BorderRadius.circular(pill);
  static BorderRadius get sheet =>
      BorderRadius.vertical(top: Radius.circular(xl.clamp(12.0, 32.0)));
}

class AppSpace {
  AppSpace._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 40;
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardTight = EdgeInsets.all(sm);
}

class AppShadow {
  AppShadow._();
  static bool get _dark => ThemeService.instance.isDarkMode;
  static ShapeDepth get _depth => PackService.shape.depth;
  static Color get _solid => _dark ? AppColors.black : AppColors.ink;

  static List<BoxShadow> _shadow({
    required Offset offset,
    required double blur,
    required double lightAlpha,
    required double darkAlpha,
    double spread = 0,
  }) {
    switch (_depth) {
      case ShapeDepth.flat:
        return const [];
      case ShapeDepth.hard:
        return [
          BoxShadow(
            color: _solid,
            offset: Offset(offset.dy.abs() / 2, offset.dy),
            blurRadius: 0,
          ),
        ];
      case ShapeDepth.soft:
        return [
          BoxShadow(
            color: _dark
                ? AppColors.black.withValues(alpha: darkAlpha)
                : AppColors.shadowLight.withValues(alpha: lightAlpha),
            offset: offset,
            blurRadius: blur,
            spreadRadius: spread,
          ),
        ];
    }
  }

  static List<BoxShadow> get card => _shadow(
    offset: const Offset(0, 4),
    blur: 10,
    lightAlpha: 0.07,
    darkAlpha: 0.35,
    spread: -1,
  );
  static List<BoxShadow> get pressed => _shadow(
    offset: const Offset(0, 1),
    blur: 4,
    lightAlpha: 0.03,
    darkAlpha: 0.2,
  );
  static List<BoxShadow> get raised => _shadow(
    offset: const Offset(0, 6),
    blur: 16,
    lightAlpha: 0.12,
    darkAlpha: 0.45,
    spread: -2,
  );
  static List<BoxShadow> get overlay => _depth == ShapeDepth.flat
      ? const []
      : [
          BoxShadow(
            color: _dark
                ? AppColors.black.withValues(alpha: 0.5)
                : AppColors.shadowLight.withValues(alpha: 0.12),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ];
}

class AppDecor {
  AppDecor._();
  static double get strokeWidth => PackService.shape.strokeWidth;
  static Border get stroke =>
      Border.all(color: AppColors.ink, width: strokeWidth);

  static BoxDecoration card({
    Color? color,
    double? radius,
    Color? borderColor,
    bool shadow = true,
  }) => BoxDecoration(
    color: color ?? AppColors.surface,
    borderRadius: BorderRadius.circular(radius ?? AppRadius.md),
    border: Border.all(
      color: borderColor ?? AppColors.border,
      width: strokeWidth,
    ),
    boxShadow: shadow ? AppShadow.card : null,
  );

  static BoxDecoration well({double? radius}) => BoxDecoration(
    color: AppColors.surfaceAlt,
    borderRadius: BorderRadius.circular(radius ?? AppRadius.sm),
    border: Border.all(color: AppColors.border, width: strokeWidth),
  );

  static BoxDecoration tinted(
    Color accent, {
    double? radius,
    bool shadow = true,
  }) => BoxDecoration(
    color: AppColors.tint(
      accent,
      ThemeService.instance.isDarkMode ? 0.20 : 0.12,
    ),
    borderRadius: BorderRadius.circular(radius ?? AppRadius.md),
    border: Border.all(
      color: AppColors.tint(accent, 0.35, base: AppColors.border),
      width: strokeWidth,
    ),
    boxShadow: shadow ? AppShadow.card : null,
  );

  static BoxDecoration filled(
    Color fill, {
    double? radius,
    bool shadow = true,
  }) => BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(radius ?? AppRadius.md),
    border: Border.all(
      color: AppColors.ink.withValues(alpha: 0.15),
      width: strokeWidth,
    ),
    // Off while pressed inside a TactileContainer — the vanishing shadow
    // is what sells the pop.
    boxShadow: shadow ? AppShadow.card : null,
  );

  static BoxDecoration pill(Color accent, {double alpha = 0.22}) =>
      BoxDecoration(
        color: AppColors.tint(accent, alpha),
        borderRadius: AppRadius.rXs,
        border: Border.all(color: AppColors.ink),
      );
}

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

    final inkSide = BorderSide(
      color: AppColors.ink,
      width: AppDecor.strokeWidth,
    );
    OutlineInputBorder fieldBorder(Color color, [double? width]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.rSm,
          borderSide: BorderSide(
            color: color,
            width: width ?? AppDecor.strokeWidth,
          ),
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
        surfaceTintColor: AppColors.transparent,
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
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rMd,
          side: inkSide,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
          side: inkSide,
        ),
        titleTextStyle: AppText.h3,
        contentTextStyle: AppText.bodyMd,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sheet,
          side: inkSide,
        ),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.bgColor,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rSm,
          side: inkSide,
        ),
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
        focusedBorder: fieldBorder(AppColors.accentWarm),
        errorBorder: fieldBorder(AppColors.danger),
        focusedErrorBorder: fieldBorder(AppColors.danger),
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
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.rSm,
            side: inkSide,
          ),
          textStyle: AppText.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textColor,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          side: inkSide,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
          textStyle: AppText.button.copyWith(color: AppColors.textColor),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: getMonoStyle(fontSize: 12, letterSpacing: 0.9),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rXs),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceAlt,
        circularTrackColor: AppColors.transparent,
        strokeCap: StrokeCap.butt,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textColor,
        contentTextStyle: getMediumStyle(
          fontSize: 13.5,
          color: AppColors.bgColor,
        ),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rSm,
          side: inkSide,
        ),
        elevation: 0,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surface,
        ),
        checkColor: WidgetStatePropertyAll(AppColors.onPrimary),
        side: inkSide,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXs),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.ink,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDeep
              : AppColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accentFill
              : AppColors.surfaceDim,
        ),
        trackOutlineColor: WidgetStatePropertyAll(AppColors.ink),
        trackOutlineWidth: WidgetStatePropertyAll(AppDecor.strokeWidth),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primarySoft,
        side: inkSide,
        labelStyle: AppText.mono,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXs),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.rXs,
          border: Border.all(color: AppColors.ink, width: AppDecor.strokeWidth),
          boxShadow: AppShadow.card,
        ),
        textStyle: getMonoStyle(fontSize: 11, letterSpacing: 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rSm,
          side: inkSide,
        ),
        textStyle: AppText.bodyMd,
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
