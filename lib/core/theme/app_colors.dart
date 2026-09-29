import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'activity_packs.dart';
import 'app_theme.dart';

class _Palette {
  _Palette._();

  static const ink = Color(0xFF1E293B);
  static const inkDark = Color(0xFF3F3F46);

  static const grey0 = Color(0xFFFFFFFF);
  static const grey25 = Color(0xFFF4FAFF);
  static const grey50 = Color(0xFFE7F6FF);
  static const grey100 = Color(0xFFDFF1FB);
  static const grey200 = Color(0xFFD9EBF5);
  static const grey300 = Color(0xFFD4E5EF);
  static const grey400 = Color(0xFFCBDDE7);
  static const grey500 = Color(0xFF6E7976);
  static const grey600 = Color(0xFF3E4946);
  static const grey900 = ink;

  static const navy900 = Color(0xFF18181B);
  static const navy800 = Color(0xFF27272A);
  static const navy700 = Color(0xFF3F3F46);
  static const navy600 = Color(0xFF52525B);
  static const navy500 = Color(0xFF3F3F46);

  static const successLight = Color(
    0xFF1F7A48,
  ); // green — not the old brand teal
  static const successDark = Color(0xFF4ADE80);
  static const warningLight = Color(
    0xFFB45309,
  ); // amber — not the old brand orange
  static const warningDark = Color(0xFFFBBF24);
  static const dangerLight = Color(0xFFBA1A1A);
  static const dangerDark = Color(0xFFF87171);
  static const infoLight = Color(
    0xFF0E7490,
  ); // cyan, clear of both packs' primaries
  static const infoDark = Color(0xFF22D3EE);

  // --- Pack seed colours: the single source of truth ----------------------
  //
  // Two seeds per pack; PackPalette.seeded() derives the full sixteen-role
  // ramp from each pair. Deliberately deep and low-saturation — the muted,
  // jewel end of each hue: dark and rich, never neon — and every derived stop is contrast-checked in
  // test/pack_theme_test.dart, so a seed change that turns illegible fails CI
  // rather than shipping.
  static const biteSizePrimary = Color(0xFF145C44); // emerald
  static const biteSizeAccent = Color(0xFFB5652B); // terracotta copper
  static const groundPrimary = Color(0xFF1F3F80); // royal navy
  static const groundAccent = Color(0xFFA8792A); // antique gold

  static const shadowLight = Color(0xFF0F172A);
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);
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

  static SystemUiOverlayStyle get systemOverlayStyle => SystemUiOverlayStyle(
    statusBarColor: AppColors.transparent,
    statusBarIconBrightness: _dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: _dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: bgColor,
    systemNavigationBarIconBrightness: _dark
        ? Brightness.light
        : Brightness.dark,
  );

  static const Color logoColor1 = Color(0xFF2C3E50);
  static const Color logoColor2 = Color(0xFFE8F6F3);
  static const Color logoColor3 = Color(0xFF1ABC9C);
  static const Color logoColor4 = Color(0xFF34495E);
  static const Color logoColor5 = Color(0xFF1B2631);

  static Color get ink => _pick(_Palette.ink, _Palette.inkDark);
  static Color tint(Color accent, double amount, {Color? base}) =>
      Color.alphaBlend(accent.withValues(alpha: amount), base ?? surface);

  static PackPalette get _brand => PackService.palette;
  static Color get primary => _pick(_brand.primary, _brand.primaryDark);
  static Color get onPrimary => _pick(_Palette.grey0, _Palette.navy900);
  static Color get primaryDeep =>
      _pick(_brand.primaryDeep, _brand.primaryDeepDark);
  static Color get primarySoft =>
      _pick(_brand.primarySoft, _brand.primarySoftDark);
  static Color get primaryFixed => _brand.primaryFixed;
  static Color get primaryBorder => ink;
  static Color get accentWarm => _pick(_brand.accent, _brand.accentDark);
  static Color get accentFill => _brand.accentFill;
  static Color get onAccent => _pick(_brand.onAccent, _brand.onAccentDark);
  static Color get accentSoft =>
      _pick(_brand.accentSoft, _brand.accentSoftDark);
  static Color get secondary => _pick(_brand.secondary, _brand.secondaryDark);
  static Color get tertiary => logoColor3;
  static Color get quaternary => logoColor4;
  static Color get quinary => logoColor5;

  static Color get bgColor => _pick(_Palette.grey25, _Palette.navy900);
  static Color get surface => _pick(_Palette.grey0, _Palette.navy800);
  static Color get surfaceAlt => _pick(_Palette.grey50, _Palette.navy700);
  static Color get surfaceRaised => _pick(_Palette.grey0, _Palette.navy600);
  static Color get surfacePale => _pick(_Palette.grey200, _Palette.navy700);
  static Color get surfaceDim => _pick(_Palette.grey400, _Palette.navy500);

  static Color get scrim => _Palette.black.withValues(alpha: _pick(0.32, 0.7));
  static Color get transparent => _Palette.transparent;
  static Color get white => _Palette.grey0;
  static Color get black => _Palette.black;

  static Color get textColor =>
      _pick(_Palette.grey900, const Color(0xFFF4F4F5));
  static Color get textSecondary =>
      _pick(_Palette.grey600, const Color(0xFFA1A1AA));
  static Color get textTertiary =>
      _pick(_Palette.grey500, const Color(0xFF71717A));
  static Color get textOnBrand => _Palette.grey0;
  static Color get textOnBrandMuted => textOnBrand.withValues(alpha: 0.75);

  static Color get border =>
      _pick(const Color(0xFFCBD5E1), const Color(0xFF3F3F46));
  static Color get borderStrong =>
      _pick(const Color(0xFF94A3B8), const Color(0xFF52525B));
  static Color get divider => _pick(_Palette.grey300, _Palette.navy600);

  static Color get success =>
      _pick(_Palette.successLight, _Palette.successDark);
  static Color get warning =>
      _pick(_Palette.warningLight, _Palette.warningDark);
  static Color get danger => _pick(_Palette.dangerLight, _Palette.dangerDark);
  static Color get info => _pick(_Palette.infoLight, _Palette.infoDark);

  static Color get appBarColor => bgColor;
  static Color get appBarIconColor => textColor;

  static Color get btnColor => primary;
  static Color get btnTextColor => onPrimary;
  static Color get btnDisabledColor =>
      _pick(_Palette.grey100, _Palette.navy700);
  static Color get btnDisabledTextColor => textTertiary;

  static Color get textFieldFillColor =>
      _pick(_Palette.grey0, _Palette.navy700);
  static Color get textFieldBorderColor => border;
  static Color get textFieldBorderFocusedColor => primary;
  static Color get textFieldBorderErrorColor => danger;
  static Color get textFieldPlaceholderColor => textTertiary;
  static Color get textFieldTextColor => textColor;
  static Color get textFieldCursorColor => primary;
  static Color get textFieldLabelColor => textSecondary;

  static Color get iconColor => textColor;
  static Color get iconMuted => textTertiary;

  static Color get checkboxSelectedBgColor => primary;
  static Color get checkboxTickColor => onPrimary;
  static Color get radioSelectedColor => primary;

  static Color get navBarColor => surface;
  static Color get activeNavBarIconColor => primary;
  static Color get inActiveNavBarIconColor => textTertiary;
  static Color get navBarCartBadgeTextColor => onPrimary;

  static Color get splashColor => primary.withValues(alpha: 0.12);
  static Color get splashScreenBgColor => bgColor;

  static Color get shimmerBaseColor =>
      _pick(_Palette.grey100, _Palette.navy700);
  static Color get shimmerHighlightColor =>
      _pick(_Palette.grey50, _Palette.navy600);

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

  // --- Pack seeds ---
  static Color get biteSizePrimary => _Palette.biteSizePrimary;
  static Color get biteSizeAccent => _Palette.biteSizeAccent;
  static Color get groundPrimary => _Palette.groundPrimary;
  static Color get groundAccent => _Palette.groundAccent;
  static Color get shadowLight => _Palette.shadowLight;
}
