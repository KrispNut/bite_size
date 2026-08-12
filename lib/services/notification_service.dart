import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local Notification Service handling Cutoff warnings and Food Arrival alerts.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
    } catch (e) {
      debugPrint('ℹ️ [NOTIFICATION SERVICE] Native notification plugin requires a full app restart (run flutter run again) to bind native Android channels: $e');
    }
  }

  /// Request permissions on Android 13+ and iOS.
  Future<void> requestPermissions() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Permission request error: $e');
    }
  }

  /// Show an instant system notification when food arrives at the office.
  Future<void> showFoodArrivedNotification({
    required String announcedBy,
    required String arrivalTime,
  }) async {
    await init();
    debugPrint('🔔 [NOTIFICATION SERVICE] Triggering Food Arrived notification by $announcedBy at $arrivalTime');

    const androidDetails = AndroidNotificationDetails(
      'lunch_arrival_channel',
      'Lunch Arrival Alerts',
      channelDescription: 'High priority alerts when lunch arrives at the office table.',
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

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        1001,
        '🍲 Fresh Rotis & Salan Have Arrived!',
        '$announcedBy announced lunch is served at $arrivalTime. Bon appétit!',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Could not show notification: $e');
    }
  }

  /// Show a warning notification when cutoff time is approaching.
  Future<void> showCutoffApproachingNotification({required int minutesLeft}) async {
    await init();
    debugPrint('🔔 [NOTIFICATION SERVICE] Triggering Cutoff Approaching notification ($minutesLeft mins left)');

    const androidDetails = AndroidNotificationDetails(
      'lunch_cutoff_channel',
      'Lunch Cutoff Alerts',
      channelDescription: 'Reminders before today\'s roti count cutoff closes.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        1002,
        '⏰ Roti Count Cutoff in $minutesLeft Minutes!',
        'Roster closes at 12:30 PM. Tap to add or update your rotis now!',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Could not show cutoff notification: $e');
    }
  }

  /// Start hourly reminders if no runner is selected.
  Future<void> startRunnerReminders() async {
    await init();
    debugPrint('🔔 [NOTIFICATION SERVICE] Starting hourly runner reminders');

    const androidDetails = AndroidNotificationDetails(
      'lunch_runner_channel',
      'Tandoor Runner Reminders',
      channelDescription: 'Hourly reminders to pick a Tandoor Runner.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.periodicallyShow(
        1003,
        '🏃 No Tandoor Runner Selected!',
        'It has been an hour and no one has volunteered to fetch the rotis. Please assign someone!',
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
