library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '/core/theme/app_colors.dart';

typedef PositionAnimatorBuilder =
    Widget Function(
      BuildContext context,
      Animation<Offset> animation,
      Widget? child,
      Size size,
      Offset targetPosition,
    );

class PositionAnimatorWidget extends StatelessWidget {
  final Widget child;

  const PositionAnimatorWidget({required GlobalKey key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class PositionAnimator {
  /// The GlobalKey of the widget to which the animated widget should move.
  final GlobalKey targetWidgetKey;

  /// The GlobalKey of the widget that should be animated.
  final GlobalKey widgetKey;

  /// The duration of the animation.
  final Duration duration;

  /// The curve that defines the animation's easing.
  final Curve curve;

  /// A factor by which the size of the child widget will decrease as it moves.
  /// The value must be greater than 0.
  final double childSizeFactor;

  /// A builder function to customize the animated widget.
  /// It provides the context, animation, child widget, size, and target position.
  final PositionAnimatorBuilder? builder;

  PositionAnimator({
    required this.targetWidgetKey,
    required this.widgetKey,
    required this.duration,
    required this.curve,
    this.builder,
    this.childSizeFactor = 1.0,
  }) : assert(childSizeFactor > 0);

  void start(BuildContext context) {
    final BuildContext? targetCtx = targetWidgetKey.currentContext;
    final BuildContext? sourceCtx = widgetKey.currentContext;
    if (targetCtx == null || sourceCtx == null) {
      return;
    }
    final renderBox = targetCtx.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }
    final position = renderBox.localToGlobal(Offset.zero);
    final targetWidgetSize = renderBox.size;
    (sourceCtx as Element).visitChildElements((Element element) {
      final widget = element.widget;
      final size = element.size ?? const Size(100, 100);
      final beginPosition = (element.findRenderObject() as RenderBox)
          .localToGlobal(Offset.zero);
      final targetPosition = Offset(
        position.dx + (targetWidgetSize.width / 2),
        position.dy + (targetWidgetSize.height / 2),
      );
      final cAnimation = AnimationController(
        vsync: _CustomTickerProvider(),
        duration: duration,
      );
      final animation = Tween<Offset>(
        begin: beginPosition,
        end: targetPosition,
      ).animate(CurvedAnimation(parent: cAnimation, curve: curve));
      final entry = OverlayEntry(
        builder: (context) {
          return AnimatedBuilder(
            animation: animation,
            builder: builder != null
                ? (BuildContext context, Widget? child) =>
                      builder!(context, animation, child, size, targetPosition)
                : (BuildContext context, Widget? child) {
                    final s =
                        calculateYRatio(
                          beginPosition.dy,
                          targetPosition.dy,
                          animation.value.dy,
                        ) *
                        childSizeFactor;
                    return Positioned(
                      left: animation.value.dx,
                      top: animation.value.dy,
                      child: SizedBox(
                        width: (size.width * s).abs(),
                        height: (size.height * s).abs(),
                        child: child,
                      ),
                    );
                  },
            child: Material(color: AppColors.transparent, child: widget),
          );
        },
      );
      Overlay.of(context).insert(entry);
      cAnimation.forward(from: 0);
      Future.delayed(duration).then((_) {
        entry.remove();
        cAnimation.dispose();
      });
    });
  }

  double calculateYRatio(double startY, double endY, double currentY) {
    double totalDistance = (endY - startY).abs();
    double currentDistance = (currentY - startY).abs();

    if (totalDistance == 0) {
      return 0.0;
    }

    return 1 - (currentDistance / totalDistance);
  }
}

class _CustomTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
