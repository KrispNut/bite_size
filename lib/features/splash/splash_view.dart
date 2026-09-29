import 'dart:async';
import '/core/theme/activity_packs.dart';
import '/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '/core/widgets/screen_name.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/neo_progress_bar.dart';
import '/features/auth/auth_view.dart';
import '/features/dashboard/dashboard_view.dart';
import '/services/identity_service.dart';

/// The brand, for exactly as long as it takes to find out who you are.
///
/// It used to be a white card floating on the brand colour — a generic
/// loading animation, the name, a typewriter "Loading...", a progress bar —
/// held on screen for a fixed two and a half seconds regardless of whether
/// the session restore had finished in two hundred milliseconds. Now the
/// mark, the wordmark and the tagline sit full-bleed on the brand colour,
/// the same lockup the sign-in screen opens with so the hand-off reads as
/// one scene, and the screen leaves the moment identity is known — after a
/// short minimum so the entrance can land rather than flash.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  /// Long enough for the entrance to settle; short enough that a warm start
  /// with a cached session never feels held back.
  static const _minimumShow = Duration(milliseconds: 1100);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _rise = Tween<double>(
    begin: 14,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _go();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: no rise, no fade — the lockup is simply there.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Resolves where to go and the minimum display time in parallel, then
  /// leaves when both are done. A failure anywhere (no Supabase, no network,
  /// a rejected claim) lands on sign-in rather than hanging here.
  Future<void> _go() async {
    final minimum = Future<void>.delayed(_minimumShow);

    Widget next;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        next = const AuthView();
      } else {
        final profile = await IdentityService.instance.restore();
        next = profile == null ? const AuthView() : const DashboardView();
      }
    } catch (e) {
      debugPrint('⚠️ [SPLASH] Could not restore identity: $e');
      next = const AuthView();
    }

    await minimum;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_fadeTo(next));
  }

  /// A splash dissolves into the app; it does not slide in from the right
  /// like a page you navigated to.
  static Route<void> _fadeTo(Widget page) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 350),
  );

  @override
  Widget build(BuildContext context) =>
      ScreenName('Splash', child: _build(context));

  Widget _build(BuildContext context) {
    final labels = PackService.labels;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryDeep,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: AnimatedBuilder(
                    animation: _rise,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _rise.value),
                      child: child,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.xxl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The mark, in a single bento tile: the one place
                          // the brand's surface colour appears on this screen.
                          Container(
                            width: 128,
                            height: 128,
                            padding: const EdgeInsets.all(AppSpace.lg),
                            decoration: AppDecor.card(
                              radius: AppRadius.lg,
                              borderColor: AppColors.ink,
                              shadow: false,
                            ),
                            child: SvgPicture.asset(
                              Assets.svg.splashImage.path,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          Text(
                            labels.activityName,
                            textAlign: TextAlign.center,
                            style: getExtraBoldStyle(
                              fontSize: 36,
                              color: AppColors.textOnBrand,
                            ).copyWith(letterSpacing: -1),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            labels.tagline,
                            textAlign: TextAlign.center,
                            style: getMonoStyle(
                              fontSize: 11,
                              color: AppColors.textOnBrand.withValues(
                                alpha: 0.75,
                              ),
                              letterSpacing: 1.1,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // One indicator, and only one: the app is working, quietly,
              // at the bottom — not competing with the lockup.
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpace.huge,
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: NeoProgressBar(
                      width: 96,
                      height: 10,
                      color: AppColors.accentFill,
                      trackColor: AppColors.primary,
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
