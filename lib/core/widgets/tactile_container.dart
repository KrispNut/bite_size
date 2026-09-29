import 'package:flutter/material.dart';
import '/core/services/sound_service.dart';

/// Reusable wrapper that gives a tile or card the design system's press
/// behaviour: while a finger is down the surface travels onto the spot its
/// shadow occupied, scales in a touch, and — through [builder] — drops the
/// shadow entirely, so the element reads as physically pressed into the page
/// and "pops" back out on release.
///
/// Only when there is something to tap. With no [onTap] the wrapper is
/// inert: no gesture, no travel, and the builder is handed `flat = true` so
/// the surface renders without its shadow. That is the whole affordance
/// rule in one place — raised means tappable, flat means read-only — and it
/// is why a static card can keep using this widget with `shadow: !flat`
/// rather than carrying its own copy of the decoration.
///
/// Two ways to use it:
///
/// * `child:` — press gives travel + scale only. The child's shadow (which it
///   painted itself, before this widget ever saw it) cannot be removed from
///   out here, so prefer the builder for anything that carries one.
/// * `builder: (context, flat) => ...` — build the surface with the state in
///   hand and pass `shadow: !flat` to `AppDecor.card()` / `.tinted()` /
///   `.filled()` (or `boxShadow: flat ? null : ...`). `flat` is true while
///   pressed, and always true when there is nothing to tap.
class TactileContainer extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext context, bool flat)? builder;
  final VoidCallback? onTap;
  final double scaleFactor;
  final bool enableSound;

  const TactileContainer({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.scaleFactor = 0.97,
    this.enableSound = true,
  }) : assert(
         (child != null) != (builder != null),
         'Provide exactly one of child or builder.',
       );

  @override
  State<TactileContainer> createState() => _TactileContainerState();
}

class _TactileContainerState extends State<TactileContainer> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (widget.enableSound) {
      SoundService.instance.playTapSound();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to tap means nothing to press: no travel, no scale, and — via
    // the builder's flag — no shadow. A raised surface that sinks under a
    // finger and then does nothing is a promise the tile doesn't keep, so a
    // static tile sits flat and only tappable ones read as raised.
    if (widget.onTap == null) {
      return widget.builder?.call(context, true) ?? widget.child!;
    }

    final content = widget.builder?.call(context, _isPressed) ?? widget.child!;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        // Travel by the resting shadow's offset, so the surface lands exactly
        // where its shadow used to be while the builder removes the shadow.
        transform: Matrix4.translationValues(0, _isPressed ? 3 : 0, 0),
        child: AnimatedScale(
          scale: _isPressed ? widget.scaleFactor : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: content,
        ),
      ),
    );
  }
}
