import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '/firebase_options.dart';
import 'identity_service.dart';
import 'supabase_service.dart';

/// A ping that arrived over FCM while the app was on screen.
///
/// Android shows nothing for a foreground push on its own, which is exactly
/// the behaviour we want: on screen, the app says it; off screen, the
/// notification centre does. The dashboard listens to these and presents
/// them the same way it presents a ping off the realtime stream, deduped by
/// id, so whichever path lands first wins and the other is silent.
class ForegroundPing {
  final String id;
  final String fromName;
  final String message;

  const ForegroundPing({
    required this.id,
    required this.fromName,
    required this.message,
  });
}

/// Firebase Cloud Messaging, which is what reaches a phone whose app is
/// closed. Local notifications only ever fire from a running isolate.
///
/// The service does three things: keeps `users.fcm_token` current for
/// whoever is signed in, relays foreground pushes to the dashboard, and
/// reports whether push is wired up at all — a build without a
/// `google-services.json` still runs, it just has no push, and the realtime
/// path falls back to a local notification when the app is backgrounded.
///
/// The send side is `supabase/functions/ping-push`, fired by migration 012
/// on every `pings` insert.
class PushService {
  static final PushService instance = PushService._();
  PushService._();

  bool _enabled = false;

  /// True once Firebase initialised. False means no `google-services.json`
  /// (or no Firebase on this platform), and nothing here does anything.
  bool get isEnabled => _enabled;

  String? _token;

  /// `"$userId:$token"` of the last successful save, so a listener firing
  /// for an unrelated identity change doesn't rewrite the same row.
  String? _registeredFor;

  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<String>? _tokenSub;

  final _foreground = StreamController<ForegroundPing>.broadcast();

  /// Pings received over FCM while the app was in the foreground.
  Stream<ForegroundPing> get foregroundPings => _foreground.stream;

  /// Call once after Supabase is up. Safe to call when Firebase isn't
  /// configured; it logs and leaves push off.
  Future<void> init() async {
    if (_enabled) return;
    try {
      // Explicit options from `flutterfire configure`, so iOS works too and
      // Android doesn't depend on the Gradle plugin having run.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint(
        '📴 [PUSH] Firebase not configured — push is off. Drop '
        'google-services.json into android/app to turn it on. ($e)',
      );
      return;
    }
    _enabled = true;

    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      // iOS: a push while on screen is handled in-app, never as a banner.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    } catch (e) {
      debugPrint('⚠️ [PUSH] Permission request failed: $e');
    }

    _tokenSub = messaging.onTokenRefresh.listen((t) {
      _token = t;
      _register();
    });
    _messageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // The token is only useful once we know whose row it belongs on, and
    // identity arrives after this init (restore or sign-in).
    IdentityService.instance.addListener(_register);

    try {
      _token = await messaging.getToken();
      debugPrint('📲 [PUSH] FCM token ready (${_token?.length ?? 0} chars)');
    } catch (e) {
      debugPrint('⚠️ [PUSH] Could not get FCM token: $e');
    }
    await _register();
  }

  Future<void> _register() async {
    final uid = IdentityService.instance.appUserId;
    final token = _token;
    if (uid.isEmpty || token == null || token.isEmpty) return;
    final key = '$uid:$token';
    if (_registeredFor == key) return;
    _registeredFor = key;
    try {
      await SupabaseService.instance.saveFcmToken(userId: uid, token: token);
    } catch (e) {
      // Try again on the next identity or token event.
      _registeredFor = null;
      debugPrint('⚠️ [PUSH] Could not save FCM token: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage m) {
    final d = m.data;
    if (d['type'] != 'ping') {
      debugPrint('📨 [PUSH] Foreground message ignored (type=${d['type']})');
      return;
    }
    _foreground.add(
      ForegroundPing(
        id: (d['ping_id'] ?? m.messageId ?? '').toString(),
        fromName: (d['from_name'] ?? '').toString().trim().isEmpty
            ? 'Someone'
            : d['from_name'].toString().trim(),
        message: (d['message'] ?? '').toString(),
      ),
    );
  }

  void dispose() {
    IdentityService.instance.removeListener(_register);
    _tokenSub?.cancel();
    _messageSub?.cancel();
  }
}
