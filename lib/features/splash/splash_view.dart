import 'dart:async';
import 'package:bite_size/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/core/constants/app_constants.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/features/auth/auth_view.dart';
import '/features/dashboard/dashboard_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _rise = Tween<double>(
    begin: 18,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for the splash animation
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      AppConstants.navigate(context, const AuthView(), replacement: true);
    } else {
      AppConstants.navigate(context, const DashboardView(), replacement: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The splash owns a fixed brand gradient in both themes, so its status bar
    // icons are pinned to light regardless of the active theme.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.heroGradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -90,
                child: _Bloom(size: 340, opacity: 0.14),
              ),
              Positioned(
                bottom: -140,
                left: -110,
                child: _Bloom(size: 360, opacity: 0.10),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: AnimatedBuilder(
                    animation: _rise,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _rise.value),
                      child: child,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          Assets.lottie.splashLoading.path,
                          width: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.restaurant_rounded,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          'Bite Size',
                          style: getExtraBoldStyle(
                            color: Colors.white,
                            fontSize: 34,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: _fade,
                          child: const _TypewriterText(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  final double size;
  final double opacity;

  const _Bloom({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// A typewriter effect for "Loading..." text.
class _TypewriterText extends StatefulWidget {
  const _TypewriterText();

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  final String _fullText = "Loading...";
  String _currentText = "";
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentIndex < _fullText.length) {
        setState(() {
          _currentText += _fullText[_currentIndex];
          _currentIndex++;
        });
      } else {
        // Reset after a short delay
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _currentText = "";
            _currentIndex = 0;
          });
          _startTyping();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We add a minWidth to prevent the UI from jumping too much as it types
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      alignment: Alignment.center,
      child: Text(
        _currentText,
        style: getMediumStyle(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: 15,
        ),
      ),
    );
  }
}
