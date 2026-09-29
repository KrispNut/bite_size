import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/generated/assets.dart';
import 'app_icon.dart';

/// A GOATED animated dark mode switch widget.
/// Featuring day/night sky gradients, rotating Sun & Moon morphing,
/// and smooth spring-like sliding animations.
class AnimatedThemeSwitch extends StatelessWidget {
  const AnimatedThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDarkMode;

        return GestureDetector(
          onTap: () {
            debugPrint(
              '🖱️ [ON_TAP] Theme Switcher toggled (Transitioning to ${isDark ? 'Light' : 'Dark'} Mode)',
            );
            ThemeService.instance.toggleTheme();
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 62,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rXs,
              // Flat fills, ink stroke: the sky gradient was the last soft
              // surface left in the app bar.
              color: isDark ? const Color(0xFF16232B) : AppColors.primaryFixed,
              border: Border.all(
                color: AppColors.ink,
                width: AppDecor.strokeWidth,
              ),
              boxShadow: AppShadow.card,
            ),
            child: Stack(
              children: [
                // The mark you are switching *to*, showing through on the side
                // the knob is about to vacate.
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: isDark ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppIcon(Assets.svg.sun.path, size: 14),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: isDark ? 0 : 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AppIcon(Assets.svg.moon.path, size: 14),
                      ),
                    ),
                  ),
                ),
                // Sliding Animated Knob
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  alignment: isDark
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isDark ? AppColors.surfaceAlt : Colors.white,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppDecor.strokeWidth,
                      ),
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 400),
                        turns: isDark ? 0.5 : 0.0,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: isDark
                              ? AppIcon(
                                  Assets.svg.moon.path,
                                  key: const ValueKey('moon'),
                                  size: 15,
                                )
                              : AppIcon(
                                  Assets.svg.sun.path,
                                  key: const ValueKey('sun'),
                                  size: 15,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
