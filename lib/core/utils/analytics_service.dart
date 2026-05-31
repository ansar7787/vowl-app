import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized analytics controller to report user engagement metrics safely,
/// ensuring that analytics failure never impacts primary gameplay experience.
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Helper to safely execute Firebase Analytics calls, catching exceptions
  /// to protect the core app lifecycle from crashes.
  Future<void> _safeLog(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        debugPrint('AnalyticsService: Logged "$name" with params: $parameters');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AnalyticsService ERROR: Failed to log "$name": $e');
        debugPrint(stack.toString());
      }
    }
  }

  /// Logs a custom user event with optional generic parameters.
  Future<void> logCustomEvent(String name, [Map<String, Object>? parameters]) async {
    await _safeLog(name, parameters);
  }

  /// Reports a successfully shown or clicked advertisement.
  Future<void> logAdImpression(String adType) async {
    await _safeLog(
      'ad_impression',
      {'ad_type': adType},
    );
  }

  /// Reports a successfully completed game level.
  Future<void> logLevelComplete(String gameType, int level) async {
    await _safeLog(
      'level_complete',
      {'game_type': gameType, 'level': level},
    );
  }

  /// Reports a level completion failure (game over state).
  Future<void> logLevelFail(String gameType, int level) async {
    await _safeLog(
      'level_fail',
      {'game_type': gameType, 'level': level},
    );
  }

  /// Reports usage of an economy-based dynamic extra life rescue.
  Future<void> logRescueLifeUsed(String gameType, int level) async {
    await _safeLog(
      'rescue_life_used',
      {'game_type': gameType, 'level': level},
    );
  }

  /// Reports normal spin operations.
  Future<void> logDailySpinUsed() async {
    await _safeLog('daily_spin_used');
  }

  /// Reports spin reward multipliers earned by viewing ads.
  Future<void> logDailySpinAdWatched() async {
    await _safeLog('daily_spin_ad_watched');
  }
}
