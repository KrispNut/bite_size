import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '/core/widgets/domino_scroll.dart';
import '/generated/assets.dart';

/// Pull-to-refresh with the hand-and-fabric Lottie.
///
/// Pulling the list down lowers a hand from the top edge. It sways left and
/// right looking for the sheet until the pull reaches the trigger, then curls
/// its fingers, presses in and grips; the creases tighten if you keep pulling.
/// Let go past the trigger and the hand yanks the page up, holds it there
/// until [onRefresh] finishes, then drops it back. Let go short of it and the
/// hand slides away with the gap.
///
/// [child] must be a vertical scrollable. It gets clamping physics so the
/// pull feels the same on every platform.
class LottieRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const LottieRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<LottieRefresh> createState() => _LottieRefreshState();
}

enum _Phase { idle, pulling, settling, refreshing, closing }

class _LottieRefreshState extends State<LottieRefresh>
    with TickerProviderStateMixin {
  // Frames of assets/lottie/refresh.json, named after its markers.
  /// End of "press": the hand has searched, found the sheet and gripped it.
  static const _gripped = 22.0;

  /// Part-way into "pull": creases at full stretch, hand still holding.
  static const _taut = 27.0;

  /// Start of "hidden": the hand is gone and the fabric has settled.
  static const _away = 46.0;

  /// The page has been yanked up and settled: it waits here while loading.
  static const _settled = 57.0;

  /// Loading done: the page starts dropping back from here...
  static const _drop = 93.0;

  /// ...and has landed (with its little bounce) by here.
  static const _landed = 124.0;

  /// How far the page travels, measured from the reference video frame by frame
  /// (video px; the reference phone is 572 px wide). Pulled up and out with the
  /// fabric, overshooting a touch, then dropped back with a small bounce.
  static const List<(double, double)> _yankUp = [
    (28, 0),
    (30, -4),
    (32, -17),
    (34, -39),
    (36, -69),
    (38, -107),
    (40, -151),
    (42, -197),
    (44, -226),
    (46, -234),
    (48, -232),
    (50, -226),
    (52, -220),
    (54, -216),
    (57, -213),
  ];
  static const List<(double, double)> _dropBack = [
    (93, -213),
    (95, -207),
    (97, -197),
    (99, -183),
    (101, -165),
    (103, -143),
    (105, -118),
    (107, -89),
    (109, -58),
    (111, -26),
    (113, 0),
    (115, 11),
    (117, 13),
    (119, 9),
    (121, 5),
    (124, 0),
  ];

  /// How far the list has to come down before letting go refreshes.
  static const _trigger = 132.0;

  /// The most it comes down, however hard you pull.
  static const _maxExtent = 200.0;

  /// Where it rests while refreshing.
  static const _hold = 140.0;

  /// Where the gripping hand's knuckles sit, as a share of the canvas height.
  static const _handBottom = 0.58;

  /// How far the list moves per point the finger does, up to the trigger.
  static const _friction = 0.6;

  /// The search, from the reference's second loop: the hand comes back down
  /// (frame 100 on), sways about looking for the sheet (113 to the end), wraps
  /// round to "settle" (0-9) and curls into its grip (9-22). Measured along
  /// that path, in frames:
  static const _swayFrom = 13.0; // frame 113
  static const _found = 58.0; // frame 9: over the sheet, about to curl
  static const _grip = 71.0; // frame 22 (= [_gripped])

  static double _searchFrame(double v) => v < 49 ? 100 + v : v - 49;

  /// Where the hand is along the search path, and which way it's swaying.
  double _search = 0;
  double _sway = 1;

  /// Light and dark versions: on a dark screen the folds are drawn as light
  /// creases (dark shading would vanish into the background).
  LottieComposition? _light;
  LottieComposition? _dark;
  LottieComposition? get _composition =>
      Theme.of(context).brightness == Brightness.dark
      ? (_dark ?? _light)
      : _light;
  _Phase _phase = _Phase.idle;
  double _pulled = 0;
  bool _armed = false;

  /// Revealed height above the list, in logical pixels.
  late final _extent = AnimationController.unbounded(vsync: this);

  /// The playing frame while refreshing and closing.
  final _frame = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_tick);
  Duration _lastTick = Duration.zero;
  bool _loaded = false;
  Completer<void> _landedDone = Completer<void>();

  /// Where the list sits (logical px, + = down): the pull gap plus the yank.
  /// Drives the list and lets the rows inside bounce along with it.
  final _listY = ValueNotifier<double>(0);
  double _screenWidth = 400;

  @override
  void initState() {
    super.initState();
    AssetLottie(Assets.lottie.refresh.path).load().then((composition) {
      if (mounted) setState(() => _light = composition);
    });
    AssetLottie(Assets.lottie.refreshDark.path).load().then((composition) {
      if (mounted) setState(() => _dark = composition);
    });
    _extent.addListener(_updateListY);
    _frame.addListener(_updateListY);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenWidth = MediaQuery.sizeOf(context).width;
  }

  static double _interp(double f, List<(double, double)> pts) {
    if (f <= pts.first.$1) return pts.first.$2;
    for (var i = 1; i < pts.length; i++) {
      final (f1, v1) = pts[i];
      if (f <= f1) {
        final (f0, v0) = pts[i - 1];
        return v0 + (v1 - v0) * (f - f0) / (f1 - f0);
      }
    }
    return pts.last.$2;
  }

  /// The page's yank at a frame, in logical px.
  double _yankAt(double f) {
    final px = f < _drop ? _interp(f, _yankUp) : _interp(f, _dropBack);
    return px * _screenWidth / 572;
  }

  void _updateListY() {
    final extent = math.max(0.0, _extent.value);
    final playing = _phase == _Phase.refreshing || _phase == _Phase.closing;
    if (!playing ||
        !_ticker.isActive ||
        _search < _grip /* hasn't got hold of it yet */ ) {
      _listY.value = extent;
      return;
    }
    final f = _frame.value;
    // the gap closes as the hand hauls the page up and out of the top
    final t = ((f - 28) / 12).clamp(0.0, 1.0);
    final gap = extent * (1 - t * t * (3 - 2 * t));
    _listY.value = gap + _yankAt(f);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _extent.dispose();
    _frame.dispose();
    _listY.dispose();
    super.dispose();
  }

  static double _extentFor(double pulled) {
    final extent = pulled * _friction;
    if (extent <= _trigger) return extent;
    // Past the trigger it gets heavier, like stretching cloth.
    const room = _maxExtent - _trigger;
    final over = extent - _trigger;
    return _trigger + room * over / (over + room);
  }

  static double _frameFor(double extent) => extent <= _trigger
      ? _gripped * extent / _trigger
      : _gripped +
            (_taut - _gripped) * (extent - _trigger) / (_maxExtent - _trigger);

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axisDirection != AxisDirection.down) {
      return false;
    }
    switch (n) {
      case ScrollStartNotification(dragDetails: != null)
          when (_phase == _Phase.idle || _phase == _Phase.settling) &&
              n.metrics.extentBefore == 0:
        // Grabbing it again mid-settle picks up where it is.
        _extent.stop();
        _pulled = _extent.value / _friction;
        if (_phase == _Phase.idle) {
          _search = 2;
          _sway = 1;
        }
        _phase = _Phase.pulling;
        _startTicker();
      case ScrollUpdateNotification(:final scrollDelta?)
          when _phase == _Phase.pulling:
        _pullBy(-scrollDelta);
      case OverscrollNotification() when _phase == _Phase.pulling:
        _pullBy(-n.overscroll);
      case ScrollEndNotification() when _phase == _Phase.pulling:
        _letGo();
    }
    return false;
  }

  void _pullBy(double delta) {
    // Goes negative while the list scrolls the other way, so coming back
    // down to the top doesn't count as pulling.
    _pulled += delta;
    final extent = _extentFor(math.max(0, _pulled));
    final armed = extent >= _trigger;
    if (armed && !_armed) HapticFeedback.selectionClick();
    _armed = armed;
    _extent.value = extent;
  }

  void _letGo() {
    if (_armed) {
      _armed = false;
      _refresh();
      return;
    }
    _phase = _Phase.settling;
    _extent
        .animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        )
        .whenCompleteOrCancel(() {
          if (_phase == _Phase.settling) {
            _phase = _Phase.idle;
            _ticker.stop();
          }
        });
  }

  bool get _canAnimate =>
      _composition != null && !MediaQuery.disableAnimationsOf(context);

  void _startTicker() {
    if (!_canAnimate || _ticker.isActive) return;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  Future<void> _refresh() async {
    _phase = _Phase.refreshing;
    _loaded = false;
    _landedDone = Completer<void>();
    if (_search >= _grip) _frame.value = _frameFor(_extent.value);
    _extent.animateTo(
      _hold,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    // No animation (off, or not loaded yet): just hold the gap while loading.
    final animate = _canAnimate;
    if (animate) {
      _startTicker();
    } else {
      _ticker.stop();
    }

    try {
      await widget.onRefresh();
    } catch (_) {
      // The screen shows its own error; the page just has to come back down.
    }
    _loaded = true;
    if (!mounted) return;

    if (animate) {
      // The hand yanks the page up and holds it there until the data is in,
      // then it drops back down with a little bounce.
      await _landedDone.future;
      if (!mounted) return;
      _ticker.stop();
      _phase = _Phase.idle;
      _extent.value = 0;
      _updateListY();
      return;
    }
    _phase = _Phase.closing;
    await _extent
        .animateTo(
          0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInCubic,
        )
        .orCancel
        .catchError((_) {});
    if (!mounted) return;
    _phase = _Phase.idle;
  }

  void _tick(Duration elapsed) {
    final composition = _composition!;
    final step = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    final frames = step * composition.frameRate;

    if (_search < _grip ||
        _phase == _Phase.pulling ||
        _phase == _Phase.settling) {
      _searchStep(frames);
      return;
    }

    var frame = _frame.value + frames;
    if (frame >= _settled && frame < _drop) {
      // Page is up: wait there for the data, then let it drop.
      if (!_loaded) {
        frame = _settled;
      } else {
        frame = _drop;
        _phase = _Phase.closing;
      }
    }
    if (frame >= _landed) {
      frame = _landed;
      if (!_landedDone.isCompleted) _landedDone.complete();
    }
    _frame.value = frame;
  }

  /// Before the grip: sway about until the pull is far enough (or you've let
  /// go past it), then curl and grip. Backing off lets go of it again.
  void _searchStep(double frames) {
    final grab = _armed || _phase == _Phase.refreshing;
    if (grab) {
      // hurry through the rest of the search, then curl at the video's pace
      _search += frames * (_search < _found ? 3 : 1.4);
      _sway = 1;
    } else if (_search > _found) {
      _search = math.max(_found, _search - frames * 2);
      _sway = -1;
    } else {
      _search += frames * _sway;
      if (_search >= _found) {
        _search = _found;
        _sway = -1;
      } else if (_search <= _swayFrom && _sway < 0) {
        _search = _swayFrom;
        _sway = 1;
      }
    }
    if (_search >= _grip) {
      _search = _grip;
      _frame.value = _frameFor(math.max(_extent.value, _trigger));
    } else {
      _frame.value = _searchFrame(_search);
    }
  }

  bool _onIndicator(OverscrollIndicatorNotification n) {
    // The hand is the overscroll effect at the top.
    if (n.depth == 0 && n.leading && _phase != _Phase.idle) {
      n.disallowIndicator();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _onIndicator,
        child: AnimatedBuilder(
          animation: Listenable.merge([_extent, _frame, _listY]),
          // lets a DominoScroll inside bounce when the list snaps back up
          child: DominoShift(
            offset: _listY,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(physics: const ClampingScrollPhysics()),
              child: widget.child,
            ),
          ),
          builder: (context, child) {
            final extent = math.max(0.0, _extent.value);
            final listTop = _listY.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (extent > 0 && listTop > 0 && _composition != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _hand(_composition!, extent, listTop),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(0, _listY.value),
                  child: child,
                ),
                // a small loader while the page waits up top, like the reference
                // (only built while waiting: an idle spinner never stops ticking)
                if (_waitingUp)
                  const Positioned(
                    top: 18,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFF9A9A9A),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool get _waitingUp =>
      _phase == _Phase.refreshing && _frame.value >= _settled - 6 && !_loaded;

  /// [listTop] is the top of the list: the hand and folds ride up with it
  /// when the page is yanked, fading out as the gap closes so the cards never
  /// slide over them.
  Widget _hand(LottieComposition composition, double extent, double listTop) {
    final playing = _phase == _Phase.refreshing || _phase == _Phase.closing;
    // once the hand has gone up and out it stays gone: the return frames would
    // bring it back in behind the cards
    final double frame;
    if (!_ticker.isActive) {
      frame = _frameFor(extent); // animations off: follow the finger
    } else if (_search < _grip) {
      frame = _searchFrame(_search);
    } else if (playing) {
      frame = math.min(_frame.value, _away);
    } else {
      frame = _frameFor(math.max(extent, _trigger)); // gripped, stretching
    }
    final bounds = composition.bounds;
    // fades out over the last few points so nothing pops at rest, and quickly
    // as the page is yanked up over it
    final fade = playing
        ? math.pow((listTop / extent).clamp(0.0, 1.0), 2).toDouble()
        : (extent / 24).clamp(0.0, 1.0);

    return Semantics(
      label: _phase == _Phase.refreshing ? 'Refreshing' : null,
      liveRegion: _phase == _Phase.refreshing,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // As wide as the screen, like the reference.
          final width = constraints.maxWidth;
          final height = width * bounds.height / bounds.width;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // The hand's fingertips ride the bottom of the gap, so the arm
              // always reaches down from the top edge and the folds fan out
              // over the list below.
              Positioned(
                top: listTop - height * _handBottom,
                left: 0,
                width: width,
                height: height,
                child: Opacity(
                  opacity: fade,
                  child: RawLottie(
                    composition: composition,
                    progress: frame / composition.durationFrames,
                    frameRate: FrameRate.max,
                    // the frames get scaled up to the screen: sample them smoothly
                    filterQuality: FilterQuality.high,
                    width: width,
                    height: height,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
