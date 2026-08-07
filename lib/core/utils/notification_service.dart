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
  static const int leaderboardNotificationId = 303;
  static const int milestoneNotificationId = 404;
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
    if (path == null || path.isEmpty || !_isSafeInternalPath(path)) {
      if (path != null && kDebugMode) {
        debugPrint(
          'NotificationService: ignored unsafe notification path: $path',
        );
      }
      // Even with no specific deep link, ensure the app comes to foreground.
      // On Android, the tap itself brings the activity to front (via the
      // FLUTTER_NOTIFICATION_CLICK intent-filter); on iOS, the OS does it
      // automatically. No extra code needed here for that.
      return;
    }

    // ROBUST FIX: Try immediate navigation, but if the router context isn't
    // ready yet (cold-start race), fall back to pendingDeepLink so the
    // router's redirect logic picks it up on its next evaluation cycle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        AppRouter.router.go(path);
        if (kDebugMode) {
          debugPrint('NotificationService: navigated to $path');
        }
      } catch (e) {
        // Router not ready — set pending deep link as fallback
        AppRouter.pendingDeepLink = path;
        if (kDebugMode) {
          debugPrint(
            'NotificationService: router not ready, set pendingDeepLink: $path ($e)',
          );
        }
      }
    });
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
  ///
  /// Timing: 8:30 PM local time — optimal for both Indian (IST) and global
  /// users. This is the post-dinner, pre-bedtime window when users are most
  /// likely to be relaxing with their phone. 9 PM+ risks being too late
  /// (sleep disruption), while 7 PM is dinner time in most cultures.
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
    // Anchor to 8:30 PM local time — post-dinner learning window
    var scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      20, // 8 PM
      30, // 30 mins
    );

    // If it's already past 8:30 PM today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Streak-aware notification copy — personalised, encouraging, never annoying.
    // Messages adapt based on streak milestones to feel like genuine progress.
    final streakMessages = _getStreakNotificationCopy(currentStreak);

    await _localNotifications.zonedSchedule(
      streakReminderNotificationId,
      _t('notifications.streak_reminder_title', fallback: streakMessages.title),
      _t(
        'notifications.streak_reminder_body',
        args: [currentStreak.toString()],
        fallback: streakMessages.body,
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
        'Scheduled streak reminder for $currentStreak days at 8:30 PM local time',
      );
    }
  }

  /// Returns personalised, premium notification copy based on streak count.
  /// Messages feel like a supportive coach, not a nagging alarm.
  ({String title, String body}) _getStreakNotificationCopy(int streak) {
    if (streak >= 30) {
      // Legendary status — celebrate mastery
      final options = [
        (
          title: '$streak days — you\'re legendary \u{1F451}',
          body: 'Most people quit by day 7. You\'re built different.',
        ),
        (
          title: 'One month strong \u{1F3C6}',
          body: 'Your consistency is paying off. Keep that crown.',
        ),
        (
          title: '$streak-day streak \u{1F525}',
          body: 'You\'re in the top 1% of learners. Quick round tonight?',
        ),
      ];
      return options[_idRandom.nextInt(options.length)];
    } else if (streak >= 14) {
      // Strong habit — reinforce confidence
      final options = [
        (
          title: 'Two weeks and counting \u{2728}',
          body: '$streak days of growth. Tonight\'s round takes 2 minutes.',
        ),
        (
          title: 'You\'ve built a real habit \u{1F4AA}',
          body: '$streak days in. Don\'t let tomorrow be day zero.',
        ),
        (
          title: 'Halfway to legendary \u{1F680}',
          body: '$streak consecutive days — you\'re almost there.',
        ),
      ];
      return options[_idRandom.nextInt(options.length)];
    } else if (streak >= 7) {
      // One week — first major milestone
      final options = [
        (
          title: 'A full week \u{1F3AF}',
          body: '$streak days! Most people never make it this far.',
        ),
        (
          title: 'Week ${streak ~/ 7} complete \u{1F389}',
          body: 'Your future self will thank you. 2-minute round?',
        ),
        (
          title: 'Building momentum \u{26A1}',
          body: '$streak days of practice. Keep the rhythm going tonight.',
        ),
      ];
      return options[_idRandom.nextInt(options.length)];
    } else if (streak >= 3) {
      // Early commitment — encourage consistency
      final options = [
        (
          title: '$streak days in a row \u{1F525}',
          body: 'You\'re building something great. Quick round tonight?',
        ),
        (
          title: 'Streak protected so far \u{1F6E1}\u{FE0F}',
          body: 'Don\'t let $streak days of effort go to waste.',
        ),
        (
          title: 'Your streak is growing \u{1F331}',
          body: '$streak days! Just one more round to keep it alive.',
        ),
      ];
      return options[_idRandom.nextInt(options.length)];
    } else {
      // Just starting — gentle, inviting
      final options = [
        (
          title: 'Your evening learning window \u{1F319}',
          body: 'A quick 2-minute round before bed makes all the difference.',
        ),
        (
          title: 'Ready for tonight\'s round? \u{1F3AE}',
          body: 'Small steps, big results. Let\'s keep the streak alive.',
        ),
        (
          title: 'Winding down? Perfect time to learn \u{1F4D6}',
          body: 'One round takes less time than scrolling. Give it a try.',
        ),
      ];
      return options[_idRandom.nextInt(options.length)];
    }
  }

  /// SCHEDULES WEEKLY MOTIVATION
  ///
  /// Timing: Sunday 10:30 AM local time — the ideal "fresh start" moment.
  /// Sunday evening (previous 6:30 PM) competes with family time and
  /// entertainment. Sunday morning gives users a motivational nudge when
  /// they're planning their week ahead.
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
          channelDescription: 'Sunday motivation!',
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

    // Rotating weekly messages — keeps the notification feeling fresh
    final weeklyMessages = [
      (
        title: 'New week, new words \u{1F4DA}',
        body: 'Start your week with a quick learning session.',
      ),
      (
        title: 'Sunday Reset \u{2728}',
        body: 'Top learners practice on weekends. A 3-minute round?',
      ),
      (
        title: 'Your weekly head start \u{1F680}',
        body: 'Get ahead this week — one round sets the tone.',
      ),
    ];
    final msg = weeklyMessages[_idRandom.nextInt(weeklyMessages.length)];

    await _localNotifications.zonedSchedule(
      weeklyMotivationNotificationId,
      _t('notifications.weekly_motivation_title', fallback: msg.title),
      _t('notifications.weekly_motivation_body', fallback: msg.body),
      _nextInstanceOfSundayMorning(location),
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
      debugPrint('Scheduled weekly motivation for Sundays at 10:30 AM');
    }
  }

  /// Returns the next Sunday at 10:30 AM local time.
  tz.TZDateTime _nextInstanceOfSundayMorning(tz.Location location) {
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      10, // 10 AM
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

  /// SCHEDULES A LEADERBOARD CHALLENGE NOTIFICATION
  ///
  /// Called after a game session completes to encourage competitive play.
  /// Timing: Next day at 12:30 PM (lunch break — high engagement window).
  Future<void> scheduleLeaderboardChallenge() async {
    final enabled = await _areNotificationsEnabled;
    if (!enabled) {
      await _localNotifications.cancel(leaderboardNotificationId);
      return;
    }

    // Cancel existing to avoid stacking
    await _localNotifications.cancel(leaderboardNotificationId);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          mainChannelId,
          'Main Notifications',
          channelDescription: 'Game updates and challenges',
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
    final now = tz.TZDateTime.now(location);
    // Tomorrow at 12:30 PM — lunch break learning window
    var scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day + 1,
      12, // 12 PM
      30, // 30 mins
    );

    final leaderboardMessages = [
      (
        title: 'Climb the leaderboard \u{1F3C6}',
        body: 'Other learners are gaining XP. Defend your rank!',
      ),
      (
        title: 'Lunchtime challenge \u{26A1}',
        body: 'One quick round could push you up the rankings.',
      ),
      (
        title: 'Your rivals are practicing \u{1F440}',
        body: 'Stay competitive — a 2-minute session keeps you in the game.',
      ),
    ];
    final msg =
        leaderboardMessages[_idRandom.nextInt(leaderboardMessages.length)];

    await _localNotifications.zonedSchedule(
      leaderboardNotificationId,
      _t('notifications.leaderboard_title', fallback: msg.title),
      _t('notifications.leaderboard_body', fallback: msg.body),
      scheduledDate,
      platformDetails,
      androidScheduleMode: useExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: AppRouter.leaderboardRoute,
    );

    if (kDebugMode) {
      debugPrint('Scheduled leaderboard challenge for tomorrow at 12:30 PM');
    }
  }

  /// Shows an immediate milestone celebration notification.
  ///
  /// Called when the user reaches a significant achievement (level up,
  /// streak milestone, etc.). These are shown immediately, not scheduled.
  Future<void> showMilestoneNotification({
    required String milestoneName,
    required String description,
  }) async {
    final enabled = await _areNotificationsEnabled;
    if (!enabled) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          mainChannelId,
          'Main Notifications',
          channelDescription: 'Achievement celebrations',
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
      milestoneNotificationId,
      milestoneName,
      description,
      platformDetails,
      payload: AppRouter.streakRoute,
    );
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
