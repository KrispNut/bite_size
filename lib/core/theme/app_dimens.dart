import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'theme_service.dart';

/// Corner radii. One ramp, used everywhere — no more ad-hoc 12/14/16/20 mixes.
class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius get rXs => BorderRadius.circular(xs);
  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rPill => BorderRadius.circular(pill);

  /// Top-only radius for bottom sheets.
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(xl));
}

/// 4pt spacing ramp. Prefer these over raw numbers.
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

  /// Standard horizontal gutter for scrollable page content.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardTight = EdgeInsets.all(sm);
}

/// Layered shadows. Dark mode gets deeper, lower-opacity shadows because
/// elevation there is carried mostly by surface tint, not by drop shadow.
class AppShadow {
  AppShadow._();

  static bool get _dark => ThemeService.instance.isDarkMode;

  /// Resting surface (roster tiles, list cards).
  static List<BoxShadow> get card => _dark
      ? const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x0D101828),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ];

  /// Raised surface (hero card, FAB-like CTAs, dialogs).
  static List<BoxShadow> get raised => _dark
      ? const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ];

  /// Colored glow beneath a primary-filled element.
  static List<BoxShadow> glow(Color color, {double opacity = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: _dark ? opacity * 0.5 : opacity),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Sheet / drawer scrim shadow.
  static List<BoxShadow> get overlay => [
        BoxShadow(
          color: Colors.black.withValues(alpha: _dark ? 0.5 : 0.12),
          blurRadius: 32,
          offset: const Offset(0, -6),
        ),
      ];
}

/// Reusable decorations so surfaces stay consistent across features.
class AppDecor {
  AppDecor._();

  /// Standard content card: surface fill, hairline border, soft shadow.
  static BoxDecoration card({
    Color? color,
    double radius = AppRadius.md,
    Color? borderColor,
    bool shadow = true,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: shadow ? AppShadow.card : null,
      );

  /// Flat, borderless "well" used for secondary/inset content.
  static BoxDecoration well({double radius = AppRadius.md}) => BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      );

  /// Tinted status card (success / warning / danger / info states).
  static BoxDecoration tinted(Color accent, {double radius = AppRadius.md}) =>
      BoxDecoration(
        color: accent.withValues(alpha: ThemeService.instance.isDarkMode ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      );

  /// The brand hero gradient used on the headline counter card.
  static BoxDecoration heroGradient({double radius = AppRadius.lg}) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadow.glow(AppColors.primary, opacity: 0.3),
      );

  /// Small pill used for metadata / badges.
  static BoxDecoration pill(Color accent, {double alpha = 0.12}) =>
      BoxDecoration(
        color: accent.withValues(alpha: alpha),
        borderRadius: AppRadius.rPill,
      );
}

/// The little grab handle at the top of every bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.borderStrong,
          borderRadius: AppRadius.rPill,
        ),
      ),
    );
  }
}
