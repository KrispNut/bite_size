import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';

/// The only place in the app that talks to Microsoft Clarity.
///
/// Two things it exists to hide. The SDK has no debug gate of its own, so
/// without [enabled] every `flutter run` would upload hot restarts and test
/// data into the same dashboard four real people land in; [enabled] is set
/// once in `main()` and is false unless this is a release build with a project
/// id configured. And Clarity's own calls are static and always available, so
/// call sites would otherwise each have to know whether a session is being
/// recorded. They don't: everything here is a no-op when it isn't.
class Analytics {
  Analytics._();

  /// True only when a Clarity session is actually being recorded.
  static bool enabled = false;

  /// Ties the replay to the person, not to a random id.
  ///
  /// Clarity generates an anonymous id per session, which answers "what
  /// happened" but never "to whom" — the first question worth asking with a
  /// roster this small. Pass the *app* user id (`public.users.id`), the same
  /// one every foreign key uses, so a replay can be lined up against the row
  /// it wrote. See `IdentityService`.
  static void identify(String appUserId) {
    if (!enabled || appUserId.isEmpty) return;
    try {
      Clarity.setCustomUserId(appUserId);
    } catch (e) {
      debugPrint('Clarity setCustomUserId failed: $e');
    }
  }

  /// Names the screen a session is on.
  ///
  /// Routes here are pushed as bare `MaterialPageRoute`s with no name, so
  /// without this Clarity has nothing to label a screen with and the funnel
  /// view is unreadable. Set through `ScreenName`, not by hand.
  static void screen(String name) {
    if (!enabled) return;
    try {
      Clarity.setCurrentScreenName(name);
    } catch (e) {
      debugPrint('Clarity setCurrentScreenName failed: $e');
    }
  }
}
