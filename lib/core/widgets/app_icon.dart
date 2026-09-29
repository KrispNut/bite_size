import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders one of the app's own SVG marks at [size].
///
/// The app used to draw its food and status glyphs with emoji characters,
/// which the platform renders in full colour with its own soft shading — the
/// one thing on screen that never matched the flat two-tone tiles around it.
/// These are drawn in the palette, with the same 2px ink stroke.
///
/// ```dart
/// AppIcon(Assets.svg.receipt.path, size: 20)
/// ```
class AppIcon extends StatelessWidget {
  final String asset;
  final double size;

  const AppIcon(this.asset, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(asset, width: size, height: size);
}
