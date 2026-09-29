import 'package:flutter/material.dart';
import '/services/analytics_service.dart';

/// Watches route changes so [ScreenName] can tell when its screen is back on
/// top. Registered on `MaterialApp.navigatorObservers` in `main.dart`.
final RouteObserver<ModalRoute<void>> screenObserver =
    RouteObserver<ModalRoute<void>>();

/// Names the screen it wraps, for session replay.
///
/// Wrap a view's whole body in one. Announcing the name on first build alone
/// is not enough: popping the ledger leaves the dashboard mounted, so nothing
/// would rebuild and the session would still claim to be on the ledger.
/// [RouteAware.didPopNext] is what fixes that, and it is the reason this is a
/// widget subscribed to a route observer rather than a call in `initState`.
///
/// ```dart
/// ScreenName('Ledger', child: Scaffold(...))
/// ```
class ScreenName extends StatefulWidget {
  final String name;
  final Widget child;

  const ScreenName(this.name, {super.key, required this.child});

  @override
  State<ScreenName> createState() => _ScreenNameState();
}

class _ScreenNameState extends State<ScreenName> with RouteAware {
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _route) {
      if (_route != null) screenObserver.unsubscribe(this);
      _route = route;
      // subscribe() calls didPush() straight away, which is what announces
      // the screen the first time.
      screenObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    screenObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => Analytics.screen(widget.name);

  /// The screen above this one was popped, so this is on top again.
  @override
  void didPopNext() => Analytics.screen(widget.name);

  @override
  Widget build(BuildContext context) => widget.child;
}
