import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralised analytics controller that reports user engagement metrics
/// safely, ensuring that analytics failure never impacts primary gameplay.
///
/// ### Event naming conventions
/// All event names follow the snake_case format required by Firebase Analytics
/// and are declared as private constants to prevent magic-string typos that
/// would silently create unmapped events in the dashboard.
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ── Event name constants ─────────────────────────────────────────────────
  // FIX (MEDIUM-3): Previously all event names were raw string literals
  // scattered across method bodies. A typo would silently create a new
  // unmapped event. Named constants make refactoring safe and provide
  // a single source of truth for the analytics event catalogue.

  static const String _kEventLevelComplete = 'level_complete';
  static const String _kEventLevelFail = 'level_fail';
  static const String _kEventAdImpression = 'ad_impression';
  static const String _kEventRescueLifeUsed = 'rescue_life_used';
  static const String _kEventDailySpinUsed = 'daily_spin_used';
  static const String _kEventDailySpinAdWatched = 'daily_spin_ad_watched';
  static const String _kEventQuestStarted = 'quest_started';
  static const String _kEventStreakMilestone = 'streak_milestone';
  static const String _kEventPurchaseAttempt = 'purchase_attempt';

  // ── Parameter key constants ───────────────────────────────────────────────

  static const String _kParamGameType = 'game_type';
  static const String _kParamLevel = 'level';
  static const String _kParamAdType = 'ad_type';
  static const String _kParamStreakDays = 'streak_days';
  static const String _kParamProductId = 'product_id';

  // ── Core helper ───────────────────────────────────────────────────────────

  /// Safely executes a Firebase Analytics event log, catching all exceptions
  /// so that analytics failure never propagates to the game loop.
  Future<void> _safeLog(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        debugPrint('Analytics: "$name" params=$parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Analytics ERROR — failed to log "$name": $e');
      }
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Logs a custom event. Prefer the typed methods below for known events.
  Future<void> logCustomEvent(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    await _safeLog(name, parameters);
  }

  /// Reports a shown or clicked advertisement.
  Future<void> logAdImpression(String adType) async {
    await _safeLog(_kEventAdImpression, {_kParamAdType: adType});
  }

  /// Reports a successfully completed game level.
  Future<void> logLevelComplete(String gameType, int level) async {
    await _safeLog(_kEventLevelComplete, {
      _kParamGameType: gameType,
      _kParamLevel: level,
    });
  }

  /// Reports a level-failure / game-over event.
  Future<void> logLevelFail(String gameType, int level) async {
    await _safeLog(_kEventLevelFail, {
      _kParamGameType: gameType,
      _kParamLevel: level,
    });
  }

  /// Reports usage of an economy-based extra-life rescue.
  Future<void> logRescueLifeUsed(String gameType, int level) async {
    await _safeLog(_kEventRescueLifeUsed, {
      _kParamGameType: gameType,
      _kParamLevel: level,
    });
  }

  /// Reports a daily spin wheel usage.
  Future<void> logDailySpinUsed() async {
    await _safeLog(_kEventDailySpinUsed);
  }

  /// Reports a rewarded-ad watch for spin multiplication.
  Future<void> logDailySpinAdWatched() async {
    await _safeLog(_kEventDailySpinAdWatched);
  }

  /// Reports when a user starts a quest (session begin).
  Future<void> logQuestStarted(String gameType, int level) async {
    await _safeLog(_kEventQuestStarted, {
      _kParamGameType: gameType,
      _kParamLevel: level,
    });
  }

  /// Reports a streak milestone reached (e.g., 7, 30, 100 days).
  Future<void> logStreakMilestone(int streakDays) async {
    await _safeLog(_kEventStreakMilestone, {_kParamStreakDays: streakDays});
  }

  /// Reports when a user initiates an in-app purchase flow.
  Future<void> logPurchaseAttempt(String productId) async {
    await _safeLog(_kEventPurchaseAttempt, {_kParamProductId: productId});
  }
}
