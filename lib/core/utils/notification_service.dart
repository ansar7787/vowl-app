import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint("Handling a background message: ${message.messageId}");
  }
}

/// CRITICAL FIX: Top-level handler for local notification taps when the app
/// is TERMINATED (killed). Without this, tapping a streak/weekly reminder
/// after swiping the app away does nothing — the Dart isolate cold-starts
/// but has no callback to process the tap.
///
/// This function runs in a FRESH isolate with NO access to the widget tree,
/// DI container, or AppRouter. The only safe action is to persist the
/// payload so that the main isolate can pick it up on startup.
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  // We cannot navigate here — no router, no DI, no widget tree.
  // Instead, persist the payload to SharedPreferences so the main
  // isolate can read it during init() and set pendingDeepLink.
  final payload = response.payload;
  if (payload != null && payload.isNotEmpty) {
    // SharedPreferences.getInstance() is safe to call from any isolate.
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('pending_notification_route', payload);
    });
  }
}

class NotificationService {
  NotificationService({LocaleService? localeService})
    : _localeService = localeService;

  // Optional — when wired up via DI, notification copy is localized through
  // LocaleService.tr(). When omitted (existing DI registrations keep
  // compiling unchanged), text falls back to the original English strings.
  final LocaleService? _localeService;

  String _t(
    String key, {
    List<String> args = const [],
    required String fallback,
  }) {
    final service = _localeService;
    if (service == null) return fallback;
    return service.tr(key, args: args, fallback: fallback);
  }

  // Service configuration constraints
  static const String mainChannelId = 'vowl_main_channel';
  static const String streakChannelId = 'vowl_streak_channel';
  static const String weeklyChannelId = 'vowl_weekly_channel';
  static const String highImportanceChannelId = 'high_importance_channel';

  static const int streakReminderNotificationId = 101;
  static const int weeklyMotivationNotificationId = 202;
  static const int maxLocalNotificationModulo = 100000;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Random _idRandom = Random();
  bool _timezoneInitialized = false;

  // StreamSubscriptions to prevent memory leaks & duplicate notifications
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  /// Check if notifications are enabled via user preferences
  Future<bool> get _areNotificationsEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  /// Crash-proof getter resolving current local location or falling back to UTC safely
  tz.Location get _currentLocation {
    if (_timezoneInitialized) {
      try {
        return tz.local;
      } catch (_) {
        // Fallback to UTC if local location is corrupted/null
      }
    }
    return tz.UTC;
  }

  Future<void> init() async {
    // 1. Cancel existing active subscriptions to prevent memory leaks during re-init
    await _cancelSubscriptions();

    // 2. Initialize Timezones
    tz.initializeTimeZones();
    String timeZoneName = 'UTC';
    try {
      final dynamic timeZoneResult = await FlutterTimezone.getLocalTimezone();
      timeZoneName = timeZoneResult.toString();

      // Resilient parsing for various OS formats
      if (timeZoneName.contains('/')) {
        final RegExp regex = RegExp(r'([A-Za-z]+/[A-Za-z_]+)');
        final match = regex.firstMatch(timeZoneName);
        if (match != null) {
          timeZoneName = match.group(0)!;
        }
      }

      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _timezoneInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Timezone initialization error: $e. Falling back to UTC.');
      }
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
        _timezoneInitialized = true;
      } catch (inner) {
        if (kDebugMode) debugPrint('Critical timezone failure: $inner');
      }
    }

    // 3. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          debugPrint('Local Notification tapped! Payload: ${response.payload}');
        }
        // BUG FIX: previously only the remote (FCM) tap handlers actually
        // navigated anywhere; tapping a locally-scheduled reminder (streak,
        // weekly motivation) was a dead end. Both now carry a `payload`
        // (see scheduleStreakReminder/scheduleWeeklyMotivation) and route
        // through the same validated navigation path.
        _handleNotificationTap(response.payload);
      },
      // CRITICAL FIX: This is the key callback that production apps register.
      // When the app is TERMINATED and the user taps a local notification,
      // flutter_local_notifications cold-starts a background isolate and
      // invokes this top-level function. It persists the route to
      // SharedPreferences so the main isolate can navigate on startup.
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    // 4. Create Notification Channels (Android 8.0+)
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            mainChannelId,
            'Main Notifications',
            description: 'Used for game updates',
            importance: Importance.max,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            streakChannelId,
            'Streak Reminders',
            description: 'Motivation alerts',
            importance: Importance.max,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            weeklyChannelId,
            'Weekly Goals',
            description: 'Weekly summaries',
            importance: Importance.high,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            highImportanceChannelId,
            'High Importance',
            description: 'Critical updates',
            importance: Importance.max,
          ),
        );
      }
    }

    // 5. Handle Foreground Messages with memory-safe subscriptions
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) async {
      if (message.notification != null) {
        final enabled = await _areNotificationsEnabled;
        if (!enabled) return;
        showNotification(
          message.notification!.title ??
              _t('notifications.fcm_default_title', fallback: 'Vowl Update'),
          message.notification!.body ??
              _t(
                'notifications.fcm_default_body',
                fallback: "Check out what's new!",
              ),
          payload: message.data['path'] as String?,
        );
      }
    });

    // 6. Get FCM Token and SAVE it to Firestore
    await _saveFCMTokenToFirestore();

    // 7. Listen for token refresh events
    _onTokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
      _updateTokenInFirestore(newToken);
    });

    // 7b. BUG FIX: a token refresh only fires when the *token itself*
    // rotates (rare). It never fires on a fresh login with an unchanged
    // token. Without this, init() running before auth completes (the
    // normal app-startup order) means the FCM token is saved exactly once
    // with no authenticated user, and never retried — that user's push
    // notifications silently never reach Firestore for the rest of the
    // session. Re-saving on every auth-state transition to a real user
    // closes that gap.
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      if (user != null) {
        _saveFCMTokenToFirestore();
      }
    });

    // 8. Handle Notification Clicks (When app is in background/terminated)
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) {
          if (kDebugMode) {
            debugPrint('Notification clicked! Path: ${message.data['path']}');
          }
          _handleNotificationTap(message.data['path'] as String?);
        });

    // 9. Check for initial message (if app was terminated and opened by notification)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        debugPrint('App opened from terminated state by notification');
      }
      final path = initialMessage.data['path'] as String?;
      if (path != null && path.isNotEmpty && _isSafeInternalPath(path)) {
        AppRouter.pendingDeepLink = path;
      }
    }

    // 10. CRITICAL FIX: Check for pending route from local notification tap
    //     in terminated state. The background isolate handler wrote the
    //     payload to SharedPreferences; we read it here and clear it.
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingRoute = prefs.getString('pending_notification_route');
      if (pendingRoute != null && pendingRoute.isNotEmpty) {
        await prefs.remove('pending_notification_route');
        if (_isSafeInternalPath(pendingRoute)) {
          // Only set if no FCM deep link already claimed priority
          AppRouter.pendingDeepLink ??= pendingRoute;
          if (kDebugMode) {
            debugPrint(
              'NotificationService: Restored pending route from terminated-state local notification: $pendingRoute',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'NotificationService: Error reading pending notification route: $e',
        );
      }
    }
  }

  /// SECURITY: `path` ultimately originates from a push-notification payload
  /// — i.e. untrusted, remotely-supplied input. We only ever forward it to
  /// the in-app router if it looks like a safe, relative in-app route
  /// (starts with `/`, no scheme/host, no parent-directory traversal, and
  /// bounded length). This blocks a malicious or compromised sender from
  /// using the notification payload to redirect the router to an external
  /// URL or an unexpectedly-crafted path.
  bool _isSafeInternalPath(String path) {
    if (path.isEmpty || path.length > 200) return false;
    if (!path.startsWith('/')) return false;
    if (path.contains('..')) return false;
    final lower = path.toLowerCase();
    if (lower.contains('://') || lower.startsWith('//')) return false;
    return true;
  }

  void _handleNotificationTap(String? path) {
    if (path != null && path.isNotEmpty && _isSafeInternalPath(path)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.router.go(path);
      });
    } else if (path != null && kDebugMode) {
      debugPrint(
        'NotificationService: ignored unsafe notification path: $path',
      );
    }
  }

  /// Saves the current FCM token to the authenticated user's Firestore document.
  Future<void> _saveFCMTokenToFirestore() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) {
        if (kDebugMode) {
          debugPrint('NotificationService: FCM token is null, skipping save.');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('FCM_TOKEN_INITIALIZED');
      }
      await _updateTokenInFirestore(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Error saving FCM token: $e');
      }
    }
  }

  /// Updates the FCM token in Firestore for the current user.
  Future<void> _updateTokenInFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) {
          debugPrint(
            'NotificationService: No authenticated user, FCM token not saved.',
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token},
      );

      if (kDebugMode) {
        debugPrint('NotificationService: FCM token saved to Firestore.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'NotificationService: Error updating FCM token in Firestore: $e',
        );
      }
    }
  }

  /// CRASH-PROOF PERMISSIONS
  ///
  /// BUG FIX: this previously returned a `Future<void>` that completed
  /// immediately — *before* the deferred `addPostFrameCallback` work even
  /// started — because the callback wasn't connected to the returned
  /// Future at all. Any caller doing `await requestPermissions();` would
  /// proceed as if permissions had been resolved when nothing had actually
  /// happened yet. A Completer now makes the returned Future genuinely
  /// resolve only once the permission flow (deferred to after the current
  /// frame, exactly as before, to avoid requesting permissions mid-build)
  /// has finished.
  Future<void> requestPermissions() async {
    final completer = Completer<void>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        NotificationSettings settings = await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          if (kDebugMode) {
            debugPrint('User granted Firebase notification permission');
          }
          await _saveFCMTokenToFirestore();
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
        if (kDebugMode) {
          debugPrint('Error requesting notification permissions: $e');
        }
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }

  Future<void> showNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    final enabled = await _areNotificationsEnabled;
    if (!enabled) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          mainChannelId,
          'Main Notifications',
          channelDescription: 'Used for game updates and streak reminders',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      _generateNotificationId(),
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// BUG FIX: the previous ID, `millisecondsSinceEpoch % 100000`, repeats on
  /// an exact 100-second cycle — any two notifications fired ~100s (or any
  /// multiple of it) apart collide on the same ID and the second silently
  /// replaces the first in the tray instead of appearing alongside it.
  /// A random ID within the same bound removes that deterministic collision
  /// pattern.
  int _generateNotificationId() =>
      _idRandom.nextInt(maxLocalNotificationModulo);

  /// SCHEDULES A STREAK REMINDER
  Future<void> scheduleStreakReminder(int currentStreak) async {
    final enabled = await _areNotificationsEnabled;
    if (!enabled) {
      await _localNotifications.cancel(streakReminderNotificationId);
      return;
    }

    // Cancel existing reminders to avoid double-messages
    await _localNotifications.cancel(streakReminderNotificationId);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          streakChannelId,
          'Streak Reminders',
          channelDescription: 'Keeps you motivated to learn!',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    bool useExact = true;
    if (Platform.isAndroid) {
      useExact = await Permission.scheduleExactAlarm.isGranted;
    }

    // Resilient timezone wait mechanism (non-blocking)
    if (!_timezoneInitialized) {
      if (kDebugMode) {
        debugPrint(
          'NotificationService: Waiting for timezone initialization...',
        );
      }
      int retry = 0;
      while (!_timezoneInitialized && retry < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retry++;
      }
    }

    final location = _currentLocation;
    final now = tz.TZDateTime.now(location);
    // Anchor to exactly 9:15 PM local time
    var scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      21, // 9 PM
      15, // 15 mins
    );

    // If it's already past 9:15 PM today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final titles = [
      'You\'re on a roll 🔥',
      'Don\'t break the chain ⚡',
      'Your streak misses you 🎯',
    ];
    final title = titles[_idRandom.nextInt(titles.length)];

    await _localNotifications.zonedSchedule(
      streakReminderNotificationId,
      _t('notifications.streak_reminder_title', fallback: title),
      _t(
        'notifications.streak_reminder_body',
        args: [currentStreak.toString()],
        fallback: '$currentStreak days strong. One quick round keeps it going.',
      ),
      scheduledDate,
      platformDetails,
      androidScheduleMode: useExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: AppRouter.streakRoute,
    );

    if (kDebugMode) {
      debugPrint(
        'Scheduled streak reminder for $currentStreak days at 9:15 PM local time',
      );
    }
  }

  /// SCHEDULES WEEKLY MOTIVATION
  Future<void> scheduleWeeklyMotivation() async {
    final enabled = await _areNotificationsEnabled;
    if (!enabled) {
      await _localNotifications.cancel(weeklyMotivationNotificationId);
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          weeklyChannelId,
          'Weekly Goals',
          channelDescription: 'Sunday morning motivation!',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    bool useExact = true;
    if (Platform.isAndroid) {
      useExact = await Permission.scheduleExactAlarm.isGranted;
    }

    final location = _currentLocation;

    await _localNotifications.zonedSchedule(
      weeklyMotivationNotificationId,
      _t(
        'notifications.weekly_motivation_title',
        fallback: 'Sunday wind-down 🎧',
      ),
      _t(
        'notifications.weekly_motivation_body',
        fallback: 'Relax with a few rounds before the week begins.',
      ),
      _nextInstanceOfSundaySixThirtyPM(location),
      platformDetails,
      androidScheduleMode: useExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: AppRouter.homeRoute,
    );

    if (kDebugMode) {
      debugPrint('Scheduled weekly motivation for Sundays at 6:30 PM');
    }
  }

  tz.TZDateTime _nextInstanceOfSundaySixThirtyPM(tz.Location location) {
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      18, // 6 PM
      30, // 30 mins
    );
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
      if (kDebugMode) debugPrint('Error getting FCM token: $e');
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

  /// Release resources, stream listeners, and active triggers to prevent leaks
  Future<void> _cancelSubscriptions() async {
    await _onMessageSubscription?.cancel();
    await _onTokenRefreshSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();
    await _authStateSubscription?.cancel();
    _onMessageSubscription = null;
    _onTokenRefreshSubscription = null;
    _onMessageOpenedAppSubscription = null;
    _authStateSubscription = null;
  }

  /// Dispose entry point for clean architectural lifecycle management
  Future<void> dispose() async {
    await _cancelSubscriptions();
  }

  /// Called when user toggles notifications in settings
  Future<void> onNotificationPreferenceChanged(bool enabled) async {
    if (!enabled) {
      await cancelAllReminders();
      if (kDebugMode) {
        debugPrint(
          'NotificationService: Notifications disabled by user. All reminders cancelled.',
        );
      }
    } else {
      await scheduleWeeklyMotivation();
      if (kDebugMode) {
        debugPrint('NotificationService: Notifications re-enabled by user.');
      }
    }
  }
}
