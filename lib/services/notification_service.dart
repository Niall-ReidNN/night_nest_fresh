import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  final List<String> nightAffirmations = [
    'Rest is productive. You deserve to sleep.',
    'Tomorrow is a fresh start.',
    'You are safe. You are home.',
    'Let go of today. You did your best.',
    'Sleep will restore your strength.',
    'Your dreams matter. You matter.',
    'Peace is waiting for you in sleep.',
    'You are worthy of rest and peace.',
  ];

  Future<void> initialize() async {
    // Skip on web platform
    if (kIsWeb) {
      debugPrint('⚠️ Notifications not supported on web');
      return;
    }

    tzdata.initializeTimeZones();
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Request notification permissions on iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleNightAffirmation({
    required int hour,
    required int minute,
  }) async {
    // Skip on web platform
    if (kIsWeb) return;
    final List<String> affirmations = nightAffirmations;
    final affirmation =
        affirmations[DateTime.now().millisecond % affirmations.length];

    try {
      await _notificationsPlugin.zonedSchedule(
        id: 0,
        title: 'Good Night 🌙',
        body: affirmation,
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'night_nest_affirmations',
            'Night Affirmations',
            channelDescription: 'Scheduled affirmations for better sleep',
            importance: Importance.low,
            priority: Priority.low,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ Scheduled night affirmation for $hour:$minute');
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;

    await _notificationsPlugin.cancelAll();
    debugPrint('✅ All notifications cancelled');
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
