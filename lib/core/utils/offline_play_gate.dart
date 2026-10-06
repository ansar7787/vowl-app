import 'package:shared_preferences/shared_preferences.dart';

/// Offline play gating for Free vs Premium users.
///
/// **Premium users**: Unlimited offline play — always allowed.
///
/// **Free users**: Limited to [maxFreePlaysPerDay] game sessions per calendar
/// day. The counter is stored locally in [SharedPreferences], so it works
/// without internet connectivity.
///
/// ### Clock manipulation
/// A user could change their device clock to reset the counter. For a language
/// learning app this is acceptable — they are only cheating themselves. For
/// strict enforcement, sync the counter to Firestore when online using server
/// timestamps.
///
/// ### Usage
/// ```dart
/// final gate = OfflinePlayGate(prefs);
///
/// // Before starting a game:
/// if (!gate.canPlay(isPremium: user.isPremium)) {
///   showLimitReachedDialog();
///   return;
/// }
///
/// // After a game session completes successfully:
/// gate.recordPlay();
/// ```
class OfflinePlayGate {
  OfflinePlayGate(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyDate = 'vowl_offline_plays_date';
  static const String _keyCount = 'vowl_offline_plays_count';

  /// Maximum number of game sessions a free user can play offline per day.
  static const int maxFreePlaysPerDay = 3;

  // ── Query ──────────────────────────────────────────────────────────────

  /// Returns `true` if the user is allowed to start a game session.
  ///
  /// Premium users are always allowed. Free users are gated to
  /// [maxFreePlaysPerDay] plays per calendar day.
  bool canPlay({required bool isPremium}) {
    if (isPremium) return true;
    return remainingPlays > 0;
  }

  /// Returns the number of remaining free plays for today.
  ///
  /// Returns [maxFreePlaysPerDay] if the stored date does not match today
  /// (i.e., the counter resets on a new day).
  int get remainingPlays {
    final today = _todayKey();
    final storedDate = _prefs.getString(_keyDate) ?? '';

    if (storedDate != today) return maxFreePlaysPerDay;

    final count = _prefs.getInt(_keyCount) ?? 0;
    return (maxFreePlaysPerDay - count).clamp(0, maxFreePlaysPerDay);
  }

  /// Returns the number of plays used today.
  int get playsUsedToday {
    final today = _todayKey();
    final storedDate = _prefs.getString(_keyDate) ?? '';

    if (storedDate != today) return 0;
    return _prefs.getInt(_keyCount) ?? 0;
  }

  // ── Mutation ───────────────────────────────────────────────────────────

  /// Records a completed game session. Call this **after** the user
  /// successfully finishes a game, not before.
  ///
  /// Automatically resets the counter when a new calendar day is detected.
  Future<void> recordPlay() async {
    final today = _todayKey();
    final storedDate = _prefs.getString(_keyDate) ?? '';

    if (storedDate != today) {
      // New day — reset
      await _prefs.setString(_keyDate, today);
      await _prefs.setInt(_keyCount, 1);
    } else {
      final count = _prefs.getInt(_keyCount) ?? 0;
      await _prefs.setInt(_keyCount, count + 1);
    }
  }

  /// Resets the daily play counter. Useful for testing or when a user
  /// upgrades to premium mid-day.
  Future<void> resetCounter() async {
    await _prefs.remove(_keyDate);
    await _prefs.remove(_keyCount);
  }

  // ── Internals ──────────────────────────────────────────────────────────

  /// Returns today's date as "YYYY-MM-DD" for stable calendar-day comparison.
  String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);
}

