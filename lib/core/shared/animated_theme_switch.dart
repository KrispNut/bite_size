import 'package:flutter/material.dart';
import '/core/theme/theme_service.dart';

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
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF141E30), const Color(0xFF243B55)]
                    : [const Color(0xFF4CA1AF), const Color(0xFFC4E0E5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF4CA1AF))
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Night Stars / Day Clouds Background Micro-details
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: isDark ? 1.0 : 0.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text('✨', style: TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: isDark ? 0.0 : 1.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Text('☁️', style: TextStyle(fontSize: 10)),
                        ),
                      ],
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
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF2B2D42) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
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
                              ? const Icon(
                                  Icons.nightlight_round,
                                  key: ValueKey('moon'),
                                  size: 15,
                                  color: Color(0xFFFFD166),
                                )
                              : const Icon(
                                  Icons.wb_sunny_rounded,
                                  key: ValueKey('sun'),
                                  size: 15,
                                  color: Color(0xFFF77F00),
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
