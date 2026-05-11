import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _timezoneInitialized = false;

  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    String timeZoneName = 'UTC';
    try {
      final dynamic timeZoneResult = await FlutterTimezone.getLocalTimezone();
      timeZoneName = timeZoneResult.toString();
      
      // Resilient parsing for various OS formats
      if (timeZoneName.contains('/')) {
        // Handle common formats like "Asia/Kolkata" or "TimezoneInfo(Asia/Kolkata)"
        final RegExp regex = RegExp(r'([A-Za-z]+/[A-Za-z_]+)');
        final match = regex.firstMatch(timeZoneName);
        if (match != null) {
          timeZoneName = match.group(0)!;
        }
      }
      
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _timezoneInitialized = true;
    } catch (e) {
      debugPrint('Timezone initialization error: $e. Falling back to UTC.');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
        _timezoneInitialized = true;
      } catch (inner) {
        debugPrint('Critical timezone failure: $inner');
      }
    }

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // 3. Create Notification Channels (Android 8.0+)
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
          'vowl_main_channel', 'Main Notifications', 
          description: 'Used for game updates', importance: Importance.max,
        ));
        await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
          'vowl_streak_channel', 'Streak Reminders', 
          description: 'Motivation alerts', importance: Importance.max,
        ));
        await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
          'vowl_weekly_channel', 'Weekly Goals', 
          description: 'Weekly summaries', importance: Importance.high,
        ));
        // Fallback for legacy or manual console notifications
        await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
          'high_importance_channel', 'High Importance', 
          description: 'Critical updates', importance: Importance.max,
        ));
      }
    }

    // 2. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          message.notification!.title ?? 'Vowl Update',
          message.notification!.body ?? 'Check out what\'s new!',
        );
      }
    });

    // 3. Get FCM Token (Log this for testing)
    String? token = await _fcm.getToken();
    if (kDebugMode) {
      debugPrint('FCM_TOKEN_INITIALIZED: $token');
    }

    // 4. Handle Notification Clicks (When app is in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked! Path: ${message.data['path']}');
      // If we have a deep link or specific route in data, we could navigate here.
      // For production, we usually use a stream or a global navigator key.
    });

    // Check for initial message (if app was terminated and opened by notification)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state by notification');
    }
  }

  /// CRASH-PROOF PERMISSIONS
  /// We wait for the first frame to ensure the Activity is ready.
  Future<void> requestPermissions() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        NotificationSettings settings = await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          debugPrint('User granted Firebase notification permission');
        }

        // Request Local Notification permission for Android 13+
        if (Platform.isAndroid) {
          final status = await Permission.notification.status;
          if (status.isDenied) {
            await Permission.notification.request();
          }
          
          final alarmStatus = await Permission.scheduleExactAlarm.status;
          if (alarmStatus.isDenied) {
            await Permission.scheduleExactAlarm.request();
          }
        }
      } catch (e) {
        debugPrint('Error requesting notification permissions: $e');
      }
    });
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vowl_main_channel',
      'Main Notifications',
      channelDescription: 'Used for game updates and streak reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      platformDetails,
    );
  }

  /// SCHEDULES A STREAK REMINDER
  /// This will notify the user in 22 hours to come back and play!
  Future<void> scheduleStreakReminder(int currentStreak) async {
    // 1. Cancel existing reminders to avoid double-messages
    await _localNotifications.cancel(101); // ID 101 reserved for streak reminders

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vowl_streak_channel',
      'Streak Reminders',
      channelDescription: 'Keeps you motivated to learn!',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Check for exact alarm permission on Android
    bool useExact = true;
    if (Platform.isAndroid) {
      useExact = await Permission.scheduleExactAlarm.isGranted;
    }

    // Ensure timezone is initialized before accessing tz.local
    if (!_timezoneInitialized) {
      debugPrint('NotificationService: Waiting for timezone initialization...');
      int retry = 0;
      while (!_timezoneInitialized && retry < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retry++;
      }
    }

    final now = _timezoneInitialized ? tz.TZDateTime.now(tz.local) : tz.TZDateTime.now(tz.UTC);

    await _localNotifications.zonedSchedule(
      101,
      'Owly is Waiting! 🦉🔥',
      'Your $currentStreak-day streak is in danger! Play now to keep it alive!',
      now.add(const Duration(hours: 22)),
      platformDetails,
      androidScheduleMode: useExact 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    if (kDebugMode) {
      debugPrint('Scheduled streak reminder for $currentStreak days (22 hours from now)');
    }
  }

  /// SCHEDULES WEEKLY MOTIVATION
  /// Notifies the user every Sunday morning to review their progress.
  Future<void> scheduleWeeklyMotivation() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vowl_weekly_channel',
      'Weekly Goals',
      channelDescription: 'Sunday morning motivation!',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Schedule for Sunday at 10:00 AM
    await _localNotifications.zonedSchedule(
      202, // Unique ID for weekly motivation
      'Sunday Study Session! 📚',
      'Ready to crush your goals this week? Let\'s review what you learned!',
      _nextInstanceOfSundayTenAM(),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    if (kDebugMode) {
      debugPrint('Scheduled weekly motivation for Sundays at 10 AM');
    }
  }

  tz.TZDateTime _nextInstanceOfSundayTenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  /// GETS THE UNIQUE FCM TOKEN FOR THIS DEVICE
  Future<String?> getFCMToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// CANCELS ALL SCHEDULED NOTIFICATIONS
  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
    if (kDebugMode) {
      debugPrint('All notifications cancelled.');
    }
  }
}
