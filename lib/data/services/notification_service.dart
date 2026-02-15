import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Get local timezone
    String timeZoneName;
    try {
      final dynamic localTimezone = await FlutterTimezone.getLocalTimezone();
      // Handle both String and TimezoneInfo return types for compatibility
      if (localTimezone is String) {
        timeZoneName = localTimezone;
      } else {
        // Assume TimezoneInfo or similar object with identifier
        timeZoneName = (localTimezone as dynamic).identifier;
      }
    } catch (e) {
      // Fallback
      timeZoneName = 'UTC';
      debugPrint('Error getting timezone: $e');
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback if location not found
      tz.setLocalLocation(tz.getLocation('UTC'));
       debugPrint('Error setting location for $timeZoneName: $e');
    }

    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );

    // Request permissions
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: false,
          );
    }
  }

  Future<void> scheduleDailySilentNotifications() async {
    // Cancel all existing notifications to avoid duplicates and ensure randomness
    await flutterLocalNotificationsPlugin.cancelAll();

    final Random random = Random();

    final now = tz.TZDateTime.now(tz.local);

    // Schedule for next 3 days
    for (int day = 0; day < 3; day++) {
       List<int> hours = [];
       while (hours.length < 2) {
         int h = random.nextInt(24);
         if (!hours.contains(h)) {
           hours.add(h);
         }
       }
       hours.sort();

       for (int i = 0; i < hours.length; i++) {
         int hour = hours[i];
         int minute = random.nextInt(60);

         tz.TZDateTime scheduledDate = tz.TZDateTime(
           tz.local,
           now.year,
           now.month,
           now.day,
           hour,
           minute,
         ).add(Duration(days: day));

         if (scheduledDate.isBefore(now)) {
           continue;
         }

         await _scheduleNotification(
           id: day * 10 + i,
           title: 'AniDong Updates',
           body: 'Jangan lupa cek update terbaru hari ini!',
           scheduledDate: scheduledDate,
         );
       }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'silent_channel_id',
          'Silent Notifications',
          channelDescription: 'Daily silent notifications',
          importance: Importance.low, // Silent
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
