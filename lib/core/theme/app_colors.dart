import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/theme/theme_service.dart';

class _Palette {
  _Palette._();

  // --- Brand teal ---------------------------------------------------------
  static const teal100 = Color(0xFFC3F5EC);
  static const teal400 = Color(0xFF2DD4BF);
  static const teal600 = Color(0xFF0B8177);
  static const teal700 = Color(0xFF0A6A60);
  static const teal800 = Color(0xFF0B554E);
  static const teal900 = Color(0xFF052F2A);

  // --- Brand navy (deep neutral, carries the dark theme) -------------------
  static const navy900 = Color(0xFF0B1117);
  static const navy800 = Color(0xFF111A22);
  static const navy700 = Color(0xFF18242E);
  static const navy600 = Color(0xFF22323E);
  static const navy500 = Color(0xFF31444F);

  // --- Neutrals (light theme) ---------------------------------------------
  static const grey0 = Color(0xFFFFFFFF);
  static const grey25 = Color(0xFFF7F9FA);
  static const grey50 = Color(0xFFF2F5F7);
  static const grey100 = Color(0xFFEAEEF1);
  static const grey200 = Color(0xFFE0E6EA);
  static const grey300 = Color(0xFFCBD4DA);
  static const grey500 = Color(0xFF7C8A95);
  static const grey600 = Color(0xFF55636D);
  static const grey900 = Color(0xFF0D1519);

  // --- Warm "tandoor" accent ----------------------------------------------
  static const amberLight = Color(0xFFC2680B);
  static const amberDark = Color(0xFFF6B93B);

  // --- Semantic -----------------------------------------------------------
  static const successLight = Color(0xFF0E7C57);
  static const successDark = Color(0xFF3DDC97);
  static const warningLight = Color(0xFF9A5B08);
  static const warningDark = Color(0xFFF5B841);
  static const dangerLight = Color(0xFFC53434);
  static const dangerDark = Color(0xFFFF8080);
  static const infoLight = Color(0xFF1D5FD1);
  static const infoDark = Color(0xFF6BA6FF);
}

class AppColors {
  AppColors._();

  static Brightness? _pinned;

  static bool get _dark => _pinned != null
      ? _pinned == Brightness.dark
      : ThemeService.instance.isDarkMode;

  static T _pick<T>(T light, T dark) => _dark ? dark : light;

  static T resolveFor<T>(Brightness brightness, T Function() build) {
    final previous = _pinned;
    _pinned = brightness;
    try {
      return build();
    } finally {
      _pinned = previous;
    }
  }

  // =========================================================================
  // SYSTEM CHROME
  // =========================================================================
  static SystemUiOverlayStyle get systemOverlayStyle => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: _dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: _dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: bgColor,
    systemNavigationBarIconBrightness: _dark
        ? Brightness.light
        : Brightness.dark,
  );

  // =========================================================================
  // BRAND CONSTANTS (fixed — used by the logo/splash artwork)
  // =========================================================================
  static const Color logoColor1 = Color(0xFF2C3E50); // Deep Blue-Grey
  static const Color logoColor2 = Color(0xFFE8F6F3); // Soft Mint
  static const Color logoColor3 = Color(0xFF1ABC9C); // Brand Teal
  static const Color logoColor4 = Color(0xFF34495E); // Secondary Navy
  static const Color logoColor5 = Color(0xFF1B2631); // Darkest Blue

  // =========================================================================
  // CORE BRAND
  // =========================================================================

  static Color get primary => _pick(_Palette.teal600, _Palette.teal400);

  static Color get onPrimary => _pick(_Palette.grey0, _Palette.teal900);

  static Color get primarySoft => primary.withValues(alpha: _pick(0.10, 0.16));

  static Color get primaryBorder =>
      primary.withValues(alpha: _pick(0.28, 0.34));

  static List<Color> get heroGradient => _pick(
    const [_Palette.teal800, _Palette.teal600],
    const [_Palette.teal900, _Palette.teal700],
  );

  static Color get accentWarm => _pick(_Palette.amberLight, _Palette.amberDark);

  static Color get secondary => _pick(_Palette.teal100, _Palette.teal800);
  static Color get tertiary => logoColor3;
  static Color get quaternary => logoColor4;
  static Color get quinary => logoColor5;

  // =========================================================================
  // SURFACES
  // =========================================================================

  static Color get bgColor => _pick(_Palette.grey25, _Palette.navy900);

  static Color get surface => _pick(_Palette.grey0, _Palette.navy800);

  static Color get surfaceAlt => _pick(_Palette.grey50, _Palette.navy700);

  static Color get surfaceRaised => _pick(_Palette.grey0, _Palette.navy600);

  static Color get scrim => Colors.black.withValues(alpha: _pick(0.32, 0.6));

  static Color get transparent => Colors.transparent;
  static Color get white => _Palette.grey0;
  static Color get black => const Color(0xFF000000);

  // =========================================================================
  // TEXT
  // =========================================================================
  static Color get textColor =>
      _pick(_Palette.grey900, const Color(0xFFE9EEF2));
  static Color get textSecondary =>
      _pick(_Palette.grey600, const Color(0xFF9BAAB6));
  static Color get textTertiary =>
      _pick(_Palette.grey500, const Color(0xFF6B7C88));
  static Color get textOnBrand => _Palette.grey0;

  // =========================================================================
  // BORDERS & DIVIDERS
  // =========================================================================
  static Color get border => _pick(_Palette.grey200, _Palette.navy600);
  static Color get borderStrong => _pick(_Palette.grey300, _Palette.navy500);
  static Color get divider => border;

  // =========================================================================
  // SEMANTIC STATES
  // =========================================================================
  static Color get success =>
      _pick(_Palette.successLight, _Palette.successDark);
  static Color get warning =>
      _pick(_Palette.warningLight, _Palette.warningDark);
  static Color get danger => _pick(_Palette.dangerLight, _Palette.dangerDark);
  static Color get info => _pick(_Palette.infoLight, _Palette.infoDark);

  // =========================================================================
  // COMPONENT TOKENS
  // =========================================================================

  // --- App bar ---
  static Color get appBarColor => bgColor;
  static Color get appBarIconColor => textColor;

  // --- Buttons ---
  static Color get btnColor => primary;
  static Color get btnTextColor => onPrimary;
  static Color get btnDisabledColor =>
      _pick(_Palette.grey100, _Palette.navy700);
  static Color get btnDisabledTextColor => textTertiary;

  // --- Text fields ---
  static Color get textFieldFillColor =>
      _pick(_Palette.grey0, _Palette.navy700);
  static Color get textFieldBorderColor => border;
  static Color get textFieldBorderFocusedColor => primary;
  static Color get textFieldBorderErrorColor => danger;
  static Color get textFieldPlaceholderColor => textTertiary;
  static Color get textFieldTextColor => textColor;
  static Color get textFieldCursorColor => primary;
  static Color get textFieldLabelColor => textSecondary;

  // --- Icons ---
  static Color get iconColor => textColor;
  static Color get iconMuted => textTertiary;

  // --- Selection controls ---
  static Color get checkboxSelectedBgColor => primary;
  static Color get checkboxTickColor => onPrimary;
  static Color get radioSelectedColor => primary;

  // --- Navigation ---
  static Color get navBarColor => surface;
  static Color get activeNavBarIconColor => primary;
  static Color get inActiveNavBarIconColor => textTertiary;
  static Color get navBarCartBadgeTextColor => onPrimary;

  // --- Splash / feedback ---
  static Color get splashColor => primary.withValues(alpha: 0.12);
  static Color get splashScreenBgColor => bgColor;

  // --- Skeleton / shimmer ---
  static Color get shimmerBaseColor =>
      _pick(_Palette.grey100, _Palette.navy700);
  static Color get shimmerHighlightColor =>
      _pick(_Palette.grey50, _Palette.navy600);

  // =========================================================================
  // LEGACY ALIASES
  // Kept so existing call sites compile; new code should use the tokens above.
  // =========================================================================
  static Color get bgColor1 => surface;
  static Color get cardColor => surface;
  static Color get containerColor => surfaceAlt;
  static Color get containerColor1 => surface;
  static Color get containerColor2 => surfaceAlt;
  static Color get containerColor3 => border;
  static Color get containerColor4 => surfaceAlt;
  static Color get containerColor5 => surfaceAlt;
  static Color get containerColor6 => surface;
  static Color get containerColor7 => primarySoft;
  static Color get containerColor8 => surface;
  static Color get addRemoveContainerColor => primary;

  static Color get textColor1 => textSecondary;
  static Color get textColor2 => textSecondary;
  static Color get textColor3 => textColor;
  static Color get textColorPrimary => primary;

  static Color get primaryColor => primary;
  static Color get primaryColor1 => primary;

  static Color get borderColor => borderStrong;
  static Color get borderColor1 => border;
  static Color get borderColorGrey => border;

  static Color get btnTextColorWhite => onPrimary;
  static Color get btnTextColorBlack => textColor;

  static Color get iconColorBlack => iconColor;
  static Color get textFieldHintColor => textTertiary;
  static Color get textFieldBorderColorSlct => primary;
  static Color get textFieldBgColor => bgColor;

  static Color get searchBarBackground => surface;
  static Color get searchBarBorder => border;
  static Color get searchBarIconColor => textTertiary;

  static Color get categoryMenuSelectedBg => primary;
  static Color get categoryMenuUnselectedBg => surface;
  static Color get categoryMenuBorderSelected => primary;
  static Color get categoryMenuBorderUnselected => border;
  static Color get categoryMenuSelectedText => onPrimary;
  static Color get categoryMenuUnselectedText => textSecondary;

  static Color get statusBarActiveColor => primary;
  static Color get statusBarInActiveColor => border;

  static Color get horizontalCardActiveBgColor => primary;
  static Color get splashColor1 => splashColor;
}
