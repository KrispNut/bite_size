import 'dart:math';
import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';

/// A wrapper widget that performs a directional circular reveal animation
/// when the theme changes:
/// - Light -> Dark: Reveals from Top-Right corner to Bottom-Left corner.
/// - Dark -> Light: Reveals from Bottom-Left corner to Top-Right corner.
class DirectionalThemeWrapper extends StatefulWidget {
  final Widget child;

  const DirectionalThemeWrapper({super.key, required this.child});

  @override
  State<DirectionalThemeWrapper> createState() =>
      _DirectionalThemeWrapperState();
}

class _DirectionalThemeWrapperState extends State<DirectionalThemeWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;

  bool _isDark = false;
  bool _isTopRightOrigin =
      true; // true: Top-Right -> Bottom-Left, false: Bottom-Left -> Top-Right
  Color _oldBgColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _isDark = ThemeService.instance.isDarkMode;
    _oldBgColor = AppColors.bgColor;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    ThemeService.instance.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    final newIsDark = ThemeService.instance.isDarkMode;
    if (newIsDark != _isDark) {
      setState(() {
        // AppColors already reports the *new* theme by the time this fires,
        // so capture the outgoing background explicitly rather than reading it.
        _oldBgColor = AppColors.resolveFor(
          _isDark ? Brightness.dark : Brightness.light,
          () => AppColors.bgColor,
        );
        _isDark = newIsDark;
        // Light -> Dark: Top-Right -> Bottom-Left
        // Dark -> Light: Bottom-Left -> Top-Right
        _isTopRightOrigin = newIsDark;
      });
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animController.isAnimating) {
      return widget.child;
    }

    return Stack(
      children: [
        // Layer 1: Previous theme background color
        Positioned.fill(child: Container(color: _oldBgColor)),
        // Layer 2: New theme expanding from Top-Right or Bottom-Left
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ClipPath(
                clipper: _DirectionalRevealClipper(
                  fraction: _animation.value,
                  isTopRightOrigin: _isTopRightOrigin,
                ),
                child: widget.child,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DirectionalRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final bool isTopRightOrigin;

  _DirectionalRevealClipper({
    required this.fraction,
    required this.isTopRightOrigin,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = isTopRightOrigin
        ? Offset(size.width, 0) // Top-Right corner
        : Offset(0, size.height); // Bottom-Left corner

    final maxRadius = sqrt(size.width * size.width + size.height * size.height);
    final currentRadius = maxRadius * fraction;

    path.addOval(Rect.fromCircle(center: center, radius: currentRadius));
    return path;
  }

  @override
  bool shouldReclip(_DirectionalRevealClipper oldClipper) {
    return oldClipper.fraction != fraction ||
        oldClipper.isTopRightOrigin != isTopRightOrigin;
  }
}
