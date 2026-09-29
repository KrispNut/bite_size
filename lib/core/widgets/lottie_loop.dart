import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Loops a Lottie forever without warming the phone.
///
/// `Lottie.asset(repeat: true)` runs on a vsync ticker, so the whole screen is
/// redrawn 60–120 times a second for as long as it's showing, and every one
/// of those frames re-evaluates the animation's keyframes. This plays the
/// same frames at the file's own pace instead:
///
/// * a timer steps to the next frame only when the picture actually changes,
///   so Flutter draws ~25 frames a second rather than one per refresh;
/// * each frame is recorded once and replayed after that, so the Lottie
///   engine only runs during the first loop;
/// * it stops while the app is in the background, while another screen
///   covers this one, and when the system asks for reduced motion.
///
/// Give it a key per [asset]; a new asset needs a new state.
class LottieLoop extends StatefulWidget {
  final String asset;

  /// The box the animation is fitted into, like `Lottie.asset`'s
  /// width/height with `BoxFit.cover`.
  final Size size;

  const LottieLoop(this.asset, {super.key, required this.size});

  @override
  State<LottieLoop> createState() => _LottieLoopState();
}

class _LottieLoopState extends State<LottieLoop> with WidgetsBindingObserver {
  /// Anything authored faster than this is shown every other frame (or every
  /// third…). The runner is a 50fps file that holds each pose for two frames,
  /// so this still shows every pose.
  static const _maxFps = 30;

  LottieDrawable? _drawable;
  List<ui.Picture?> _frames = const [];
  int _framesPerStep = 1;
  Duration _stepInterval = Duration.zero;
  int _index = 0;
  Timer? _timer;

  bool _appVisible = true;
  bool _routeVisible = true;
  bool _motionAllowed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _appVisible = state == null || state == AppLifecycleState.resumed;
    _load();
  }

  Future<void> _load() async {
    final composition = await AssetLottie(
      widget.asset,
      backgroundLoading: true,
    ).load();
    if (!mounted) return;

    final nativeFps = composition.frameRate;
    _framesPerStep = math.max(1, (nativeFps / _maxFps).round());
    final frameCount = math.max(
      1,
      (composition.durationFrames / _framesPerStep).round(),
    );
    setState(() {
      _drawable = LottieDrawable(composition);
      _frames = List.filled(frameCount, null);
      _stepInterval = Duration(
        microseconds: (_framesPerStep / nativeFps * 1000000).round(),
      );
    });
    _syncTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // False while another route is pushed on top of this one.
    _routeVisible = TickerMode.valuesOf(context).enabled;
    _motionAllowed = !MediaQuery.disableAnimationsOf(context);
    _syncTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appVisible = state == AppLifecycleState.resumed;
    _syncTimer();
  }

  void _syncTimer() {
    final shouldRun =
        _frames.length > 1 && _appVisible && _routeVisible && _motionAllowed;
    if (shouldRun == (_timer != null)) return;

    _timer?.cancel();
    _timer = shouldRun
        ? Timer.periodic(_stepInterval, (_) {
            setState(() => _index = (_index + 1) % _frames.length);
          })
        : null;
  }

  ui.Picture _frame(int index) => _frames[index] ??= _record(index);

  ui.Picture _record(int index) {
    final recorder = ui.PictureRecorder();
    final durationFrames = _drawable!.composition.durationFrames;
    _drawable!
      ..setProgress(index * _framesPerStep / durationFrames)
      ..draw(Canvas(recorder), Offset.zero & widget.size, fit: BoxFit.cover);
    return recorder.endRecording();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (final frame in _frames) {
      frame?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.fromSize(
        size: widget.size,
        child: _drawable == null
            ? null
            : CustomPaint(painter: _PicturePainter(_frame(_index))),
      ),
    );
  }
}

class _PicturePainter extends CustomPainter {
  final ui.Picture picture;

  const _PicturePainter(this.picture);

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPicture(picture);

  @override
  bool shouldRepaint(_PicturePainter oldDelegate) =>
      oldDelegate.picture != picture;
}
