import 'package:flutter/foundation.dart';
import '/core/theme/activity_packs.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications: arrivals, departures, shared-expense invites,
/// runner reminders and pings.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
      debugPrint('🔔 [NOTIFICATION SERVICE] Initialized successfully');
      await _ensurePingChannel();
    } catch (e) {
      debugPrint(
        'ℹ️ [NOTIFICATION SERVICE] Native notification plugin requires a full app restart (run flutter run again) to bind native Android channels: $e',
      );
    }
  }

  /// Pings arrive over FCM while the app is closed, and FCM posts them to
  /// whatever channel the sender names. Android only honours the importance
  /// a channel was *created* with, so it has to exist — at max — before the
  /// first push lands, or the OS quietly makes a low-priority one instead.
  /// Channel ids are load-bearing; this one is shared with ping-push.
  Future<void> _ensurePingChannel() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'ping_channel',
        'Pings',
        description: 'Someone needs you — a direct ping from the dashboard.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Request permissions on Android 13+ and iOS.
  Future<void> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Permission request error: $e');
    }
  }

  /// Show an instant system notification when food arrives at the office.
  Future<void> showArrivalNotification({
    required String announcedBy,
    required String arrivalTime,
  }) async {
    await init();
    debugPrint(
      '🔔 [NOTIFICATION SERVICE] Triggering arrival notification by $announcedBy at $arrivalTime',
    );

    final androidDetails = AndroidNotificationDetails(
      // Channel ids are load-bearing: Android binds them at install, so
      // renaming one orphans the channel on every existing device.
      'lunch_arrival_channel',
      '${PackService.labels.activityName} Arrival Alerts',
      channelDescription:
          'High priority alerts when what was ordered actually turns up.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        1001,
        '🔔 ${PackService.labels.arrival}!',
        '$announcedBy called it at $arrivalTime.',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Could not show notification: $e');
    }
  }

  /// One notification id per shared expense, so a second event about the
  /// same expense replaces the first instead of stacking up.
  static int _expenseNotificationId(String expenseId, int offset) =>
      _expenseIdBase + offset + (expenseId.hashCode.abs() % _expenseIdSpan);

  static const int _expenseIdBase = 2000;
  static const int _expenseIdSpan = 500;

  /// Somebody put you on a shared expense. It's an ask, not a charge:
  /// nothing is owed until you accept.
  Future<void> showExpenseInviteNotification({
    required String expenseId,
    required String fromName,
    required String description,
    required int estimatedMinor,
  }) async {
    await init();
    debugPrint(
      '🔔 [NOTIFICATION SERVICE] Expense invite from $fromName for "$description"',
    );

    final androidDetails = AndroidNotificationDetails(
      'shared_order_channel',
      '${PackService.labels.expenseTitle} Invites',
      channelDescription:
          'Someone wants to split an order with you and needs an answer.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        _expenseNotificationId(expenseId, 0),
        '🤝 $fromName wants to share "$description"',
        'Your share would be about '
            '${PackService.currency.format(estimatedMinor, decimals: false)}. '
            'Open ${PackService.labels.activityName} to accept or decline — '
            'the ${PackService.labels.runner} is waiting on you.',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Could not show expense invite: $e');
    }
  }

  /// Tells the payer how someone answered. A decline matters most: their
  /// own share just went up.
  Future<void> showExpenseResponseNotification({
    required String expenseId,
    required String whoName,
    required String description,
    required bool accepted,
    required int myNewMinor,
  }) async {
    await init();
    debugPrint(
      '🔔 [NOTIFICATION SERVICE] $whoName '
      '${accepted ? 'accepted' : 'declined'} "$description"',
    );

    final androidDetails = AndroidNotificationDetails(
      'shared_order_channel',
      '${PackService.labels.expenseTitle} Invites',
      channelDescription:
          'Someone wants to split an order with you and needs an answer.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        _expenseNotificationId(expenseId, 1),
        accepted
            ? '✅ $whoName is in on "$description"'
            : '🚫 $whoName passed on "$description"',
        accepted
            ? 'Your share is now ${PackService.currency.format(myNewMinor, decimals: false)}.'
            : 'The cost re-split across everyone still in — '
                  'your share is now ${PackService.currency.format(myNewMinor, decimals: false)}.',
        details,
      );
    } catch (e) {
      debugPrint(
        '⚠️ [NOTIFICATION SERVICE] Could not show expense response: $e',
      );
    }
  }

  /// Everyone has answered, so the runner is clear to leave with it.
  Future<void> showExpenseConfirmedNotification({
    required String expenseId,
    required String description,
    required int headcount,
  }) async {
    await init();
    debugPrint('🔔 [NOTIFICATION SERVICE] Expense "$description" confirmed');

    final androidDetails = AndroidNotificationDetails(
      'shared_order_channel',
      '${PackService.labels.expenseTitle} Invites',
      channelDescription:
          'Someone wants to split an order with you and needs an answer.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        _expenseNotificationId(expenseId, 2),
        '🍽️ "$description" is confirmed',
        'Everyone has answered — split $headcount '
            '${headcount == 1 ? 'way' : 'ways'}. The runner can head out.',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Could not show confirmation: $e');
    }
  }

  /// The runner has left with the final list, so nothing can change now.
  Future<void> showRunnerDepartedNotification({
    required String runnerName,
    required String departureTime,
    required int expenseCount,
  }) async {
    await init();
    debugPrint('🔔 [NOTIFICATION SERVICE] Runner $runnerName departed');

    final androidDetails = AndroidNotificationDetails(
      'lunch_runner_channel',
      '${PackService.labels.runnerTitle} Reminders',
      channelDescription:
          'Hourly reminders to pick the ${PackService.labels.runner}.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        1004,
        '🏃 $runnerName has set off',
        expenseCount > 0
            ? 'Left at $departureTime with '
                  '${PackService.labels.expenseCount(expenseCount)}. '
                  'The list is closed.'
            : 'Left at $departureTime. The list is closed.',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Could not show departure: $e');
    }
  }

  /// Somebody tapped the Ping button, and this device is the one it reaches.
  Future<void> showPingNotification({
    required String pingId,
    required String fromName,
    required String message,
  }) async {
    await init();
    debugPrint('🔔 [NOTIFICATION SERVICE] Ping from $fromName');

    final androidDetails = AndroidNotificationDetails(
      'ping_channel',
      'Pings',
      channelDescription:
          'Someone needs you — a direct ping from the dashboard.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        // Stable per ping, so a re-delivered row can't stack a duplicate.
        3000 + (pingId.hashCode & 0xFFFF),
        '🔔 $fromName pinged you',
        message.isEmpty ? 'Open ${PackService.labels.activityName}.' : message,
        details,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Could not show ping: $e');
    }
  }

  /// Start hourly reminders if no runner is selected.
  Future<void> startRunnerReminders() async {
    await init();
    debugPrint('🔔 [NOTIFICATION SERVICE] Starting hourly runner reminders');

    final androidDetails = AndroidNotificationDetails(
      'lunch_runner_channel',
      '${PackService.labels.runnerTitle} Reminders',
      channelDescription:
          'Hourly reminders to pick the ${PackService.labels.runner}.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.periodicallyShow(
        1003,
        '🏃 No ${PackService.labels.runner} yet!',
        'It has been an hour and nobody has taken the '
            '${PackService.labels.errand}. Please assign someone.',
        RepeatInterval.hourly,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Could not start reminders: $e');
    }
  }

  /// Stop the hourly runner reminders.
  Future<void> stopRunnerReminders() async {
    debugPrint('🔔 [NOTIFICATION SERVICE] Stopping hourly runner reminders');
    try {
      await _notificationsPlugin.cancel(1003);
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Could not stop reminders: $e');
    }
  }
}
