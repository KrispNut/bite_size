import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Bouncy "domino" scrolling: while the list scrolls, every [DominoItem] lags behind
/// the content a little, then springs back into place. Items further from the one
/// under your finger lag more, so the list ripples like a chain of dominoes.
///
/// Wrap any vertical scrollable (ListView, CustomScrollView, GridView…) and wrap each
/// row in a [DominoItem] with its index:
///
/// ```dart
/// DominoScroll(
///   child: ListView.builder(
///     itemCount: items.length,
///     itemBuilder: (context, i) => DominoItem(index: i, child: FoodCard(items[i])),
///   ),
/// )
/// ```
class DominoScroll extends StatefulWidget {
  const DominoScroll({
    super.key,
    required this.child,
    this.lagPerItem = 0.08,
    this.maxLag = 0.6,
    this.stiffness = 260,
    this.damping = 20,
    this.maxOffset = 90,
    this.edgeGain = 0.35,
    this.enabled = true,
  });

  final Widget child;

  /// How much extra each row lags per row of distance from the anchor row (0..1 of the scroll delta).
  final double lagPerItem;

  /// Upper bound on the lag of any single row (0..1 of the scroll delta).
  final double maxLag;

  /// Spring pulling each row back into place. Higher = snappier.
  final double stiffness;

  /// Spring damping. Lower = more bounce (critical damping is 2 * sqrt(stiffness) ≈ 32 at 260).
  final double damping;

  /// Rows never drift further than this from their real position (logical px).
  final double maxOffset;

  /// At an edge (or on a list too short to scroll), how much the row under
  /// the finger stretches with it (0..1 of the overscroll); far rows get less.
  final double edgeGain;

  final bool enabled;

  @override
  State<DominoScroll> createState() => _DominoScrollState();
}

class _DominoScrollState extends State<DominoScroll>
    with SingleTickerProviderStateMixin {
  final Map<int, _DominoItemState> _items = {};
  final Map<int, double> _velocity = {};
  Ticker? _ticker; // created on the first scroll
  Duration? _lastTick;
  int? _anchor;

  void _register(int index, _DominoItemState item) => _items[index] = item;

  void _unregister(int index, _DominoItemState item) {
    if (identical(_items[index], item)) {
      _items.remove(index);
      _velocity.remove(index);
    }
  }

  // cached: scroll-end notifications can arrive while this widget is being torn down
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shift = context.getInheritedWidgetOfExactType<DominoShift>()?.offset;
    if (shift != _shift) {
      _shift?.removeListener(_onShift);
      _shift = shift?..addListener(_onShift);
      _lastShift = shift?.value ?? 0;
    }
  }

  /// How far an ancestor ([DominoShift]) has moved the whole list down.
  ValueListenable<double>? _shift;
  double _lastShift = 0;

  /// A finger is on the list: the drag drives the rows, not the shift.
  bool _dragging = false;

  /// The whole list moved without a scroll (a pull-to-refresh snapping back,
  /// settling or closing): rows trail from the top and bounce, like the
  /// fabric being let go.
  void _onShift() {
    final value = _shift!.value; // negative too: a refresh yanks the page up
    final moved = value - _lastShift;
    _lastShift = value;
    if (!_active || _dragging || moved == 0 || _items.isEmpty) return;
    final top = _items.keys.reduce(math.min);
    _edgeAnchorRow = top;
    // moved up (negative) = content went up: push rows back down so they trail
    _kick(top, (lag) => -moved * lag);
  }

  bool get _active => mounted && widget.enabled && !_reduceMotion;

  /// The row under a screen point (its untranslated layout box), if any is on screen.
  int? _indexAt(Offset global) {
    for (final entry in _items.entries) {
      final box = entry.value.context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final local = box.globalToLocal(global);
      if (local.dy >= 0 && local.dy <= box.size.height) return entry.key;
    }
    return null;
  }

  /// When nothing is under the finger (fling, programmatic scroll) anchor on the leading edge:
  /// the rows that enter first move first, the rest follow.
  int? _edgeAnchor(double delta) {
    if (_items.isEmpty) return null;
    final keys = _items.keys;
    return delta > 0 ? keys.reduce(math.max) : keys.reduce(math.min);
  }

  /// How far the finger has dragged past the edge in the current gesture
  /// (logical px, + = pushed up past the bottom, - = pulled down at the top).
  double _edgePull = 0;
  int? _edgeAnchorRow;

  bool _onScroll(ScrollNotification n) {
    if (!_active || n.depth != 0 || n.metrics.axis != Axis.vertical) {
      return false;
    }
    if (n is ScrollStartNotification) {
      final pos = n.dragDetails?.globalPosition;
      _anchor = pos != null ? _indexAt(pos) : null;
      _edgePull = 0;
      _dragging = pos != null;
    } else if (n is ScrollUpdateNotification) {
      final delta = n.scrollDelta ?? 0;
      if (delta == 0) return false;
      // The content is moving again, so it's no longer held against an edge.
      _edgePull = 0;
      final anchor =
          (n.dragDetails != null ? _anchor : null) ?? _edgeAnchor(delta);
      if (anchor == null) return false;
      // Content moved up by `delta`: push each row back down by part of it so
      // it trails behind, further rows more.
      _kick(anchor, (lag) => delta * lag);
    } else if (n is OverscrollNotification) {
      // At an edge (or a list too short to scroll) the content can't move, so
      // the rows stretch instead: the ones nearest the finger (or the edge a
      // fling hits) follow it most, the far ones barely, then all spring back.
      final delta = n.overscroll;
      if (delta == 0) return false;
      final anchor =
          (n.dragDetails != null ? _anchor : null) ?? _edgeAnchor(delta);
      if (anchor == null) return false;
      if (n.dragDetails != null) {
        // Held: the stretch builds with the drag (springs chase the target).
        _edgePull += delta;
        _edgeAnchorRow = anchor;
        _startTicker();
      } else {
        // A fling hit the edge: knock the rows, they bounce back.
        for (final entry in _items.entries) {
          final g = _edgeGain(entry.key, anchor);
          _velocity[entry.key] = (_velocity[entry.key] ?? 0) - delta * g * 18;
        }
        _startTicker();
      }
    } else if (n is ScrollEndNotification) {
      _anchor = null;
      _dragging = false;
      _edgePull = 0; // let go: everything springs home
    }
    return false;
  }

  double _lagOf(int row, int anchor) =>
      math.min(widget.maxLag, (row - anchor).abs() * widget.lagPerItem);

  /// Share of an edge stretch a row takes: most under the finger, none far away.
  double _edgeGain(int row, int anchor) =>
      widget.edgeGain * (1 - _lagOf(row, anchor) / widget.maxLag);

  /// Where a row is being pulled to while the finger holds an edge.
  double _targetOf(int row) {
    final anchor = _edgeAnchorRow;
    if (_edgePull == 0 || anchor == null) return 0;
    // Rubbery: easy at first, stiffer the further you go.
    final pull = -_edgePull / (1 + _edgePull.abs() / 260);
    return pull * _edgeGain(row, anchor);
  }

  /// Moves every row by `push(lag)`, where lag grows with the row's distance
  /// from [anchor], and makes sure the springs are running.
  void _kick(int anchor, double Function(double lag) push) {
    for (final entry in _items.entries) {
      final dy = push(_lagOf(entry.key, anchor));
      if (dy == 0) continue;
      final item = entry.value;
      item.offset.value = (item.offset.value + dy).clamp(
        -widget.maxOffset,
        widget.maxOffset,
      );
    }
    _startTicker();
  }

  void _startTicker() {
    final ticker = _ticker ??= createTicker(_tick);
    if (!ticker.isActive) {
      _lastTick = null;
      ticker.start();
    }
  }

  void _tick(Duration now) {
    final dt = _lastTick == null
        ? 1 / 60
        : math.min((now - _lastTick!).inMicroseconds / 1e6, 1 / 30);
    _lastTick = now;
    var moving = _edgePull != 0;
    final anchor = _edgeAnchorRow ?? _anchor;
    for (final entry in _items.entries) {
      final item = entry.value;
      var x = item.offset.value;
      var v = _velocity[entry.key] ?? 0;
      final target = _targetOf(entry.key);
      // Rows further from the finger get a softer spring, so they arrive
      // later: that delay is the domino.
      final soft = anchor == null
          ? 0.0
          : _lagOf(entry.key, anchor) / widget.maxLag;
      final k = widget.stiffness * (1 - 0.55 * soft);
      // damped spring towards the target (semi-implicit Euler, two sub-steps)
      for (var s = 0; s < 2; s++) {
        final h = dt / 2;
        v += (-k * (x - target) - widget.damping * v) * h;
        x += v * h;
      }
      x = x.clamp(-widget.maxOffset, widget.maxOffset);
      if ((x - target).abs() < 0.05 && v.abs() < 0.5) {
        x = target;
        v = 0;
      } else {
        moving = true;
      }
      _velocity[entry.key] = v;
      item.offset.value = x;
    }
    _keepApart();
    if (!moving) _ticker?.stop();
  }

  /// Rows never slide over each other: a row driven into its neighbour
  /// shoves it along, outward from the finger's row, like a real domino.
  void _keepApart() {
    final rows = _items.keys.toList()..sort();
    if (rows.length < 2) return;
    final anchor = _edgeAnchorRow ?? _anchor ?? rows.last;
    // below the finger: a row pushed down shoves the next one down
    for (var j = 1; j < rows.length; j++) {
      if (rows[j - 1] < anchor) continue;
      _separate(rows[j - 1], rows[j], moveLower: true);
    }
    // above the finger: a row pushed up shoves the one above it up
    for (var j = rows.length - 1; j > 0; j--) {
      if (rows[j] > anchor) continue;
      _separate(rows[j - 1], rows[j], moveLower: false);
    }
  }

  void _separate(int upperRow, int lowerRow, {required bool moveLower}) {
    final upper = _items[upperRow]!, lower = _items[lowerRow]!;
    final gap = _gapBetween(upper, lower);
    if (gap == null || upper.offset.value <= lower.offset.value + gap) return;
    final vu = _velocity[upperRow] ?? 0, vl = _velocity[lowerRow] ?? 0;
    if (moveLower) {
      lower.offset.value = upper.offset.value - gap;
      _velocity[lowerRow] = math.max(vu, vl);
    } else {
      upper.offset.value = lower.offset.value + gap;
      _velocity[upperRow] = math.min(vu, vl);
    }
  }

  /// Space between two rows as laid out (before any domino offset), or null if
  /// either isn't on screen.
  double? _gapBetween(_DominoItemState upper, _DominoItemState lower) {
    final a = upper.context.findRenderObject(),
        b = lower.context.findRenderObject();
    if (a is! RenderBox ||
        b is! RenderBox ||
        !a.hasSize ||
        !b.hasSize ||
        !a.attached ||
        !b.attached) {
      return null;
    }
    final bottom = a.localToGlobal(Offset(0, a.size.height)).dy;
    final top = b.localToGlobal(Offset.zero).dy;
    return math.max(0, top - bottom);
  }

  @override
  void dispose() {
    _shift?.removeListener(_onShift);
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DominoScope(
      state: this,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      ),
    );
  }
}

/// Tells a [DominoScroll] below it how far the whole list has been moved down
/// (logical px) by something other than scrolling, e.g. a pull-to-refresh
/// that translates the list. When that moves without a finger on the list
/// the rows trail and bounce.
class DominoShift extends InheritedWidget {
  const DominoShift({super.key, required this.offset, required super.child});

  final ValueListenable<double> offset;

  @override
  bool updateShouldNotify(DominoShift old) => old.offset != offset;
}

class _DominoScope extends InheritedWidget {
  const _DominoScope({required this.state, required super.child});
  final _DominoScrollState state;
  @override
  bool updateShouldNotify(_DominoScope old) => old.state != state;
}

/// One row of a [DominoScroll] list. [index] is the row's position in the list.
class DominoItem extends StatefulWidget {
  const DominoItem({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<DominoItem> createState() => _DominoItemState();
}

class _DominoItemState extends State<DominoItem> {
  final ValueNotifier<double> offset = ValueNotifier(0);
  _DominoScrollState? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context
        .dependOnInheritedWidgetOfExactType<_DominoScope>()
        ?.state;
    if (scope != _scope) {
      _scope?._unregister(widget.index, this);
      _scope = scope?.._register(widget.index, this);
    }
  }

  @override
  void didUpdateWidget(DominoItem old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _scope?._unregister(old.index, this);
      _scope?._register(widget.index, this);
    }
  }

  @override
  void dispose() {
    _scope?._unregister(widget.index, this);
    offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      child: widget.child,
      builder: (context, dy, child) =>
          Transform.translate(offset: Offset(0, dy), child: child),
    );
  }
}
