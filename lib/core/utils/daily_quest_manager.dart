import 'package:flutter/foundation.dart';

/// Centralised coordinator responsible for calculating daily quest rotations
/// based on exact local calendar dates, preventing shifts during daylight
/// saving transitions.
///
/// ### DST safety
/// This class projects local calendar dates to exact UTC midnight boundaries
/// before computing the epoch delta. Because `DateTime.utc(y, m, d)` always
/// produces midnight-UTC regardless of the local timezone, `difference.inDays`
/// is always a precise multiple of 24 hours — immune to daylight saving jumps.
///
/// ### Level range
/// Daily quest levels currently rotate through 1–5. This is intentionally kept
/// low to act as a "gateway" challenge accessible to all users. As users
/// progress, the home screen separately surfaces higher-difficulty quests
/// calibrated to their unlocked level.
class DailyQuestManager {
  // Private constructor to prevent unnecessary instance allocations.
  const DailyQuestManager._();

  /// Epoch anchor date. Day-delta from this date drives the rotation cycle.
  static final DateTime _epoch = DateTime(2024, 1, 1);

  /// Category rotation order (4-day cycle).
  static const List<String> _categoryRotation = [
    'reading',
    'writing',
    'speaking',
    'grammar',
  ];

  /// Number of distinct level values in the rotation (1–_levelRange).
  static const int _levelRange = 5;

  /// Returns the category and level for today's daily quest.
  ///
  /// Returns a Map with:
  /// - `'category'` — e.g. `'reading'`, `'writing'`, `'speaking'`, `'grammar'`
  /// - `'level'`    — integer in the range [1, [_levelRange]]
  ///
  /// The result is deterministic for the same calendar date across devices
  /// and timezones, making multi-player daily-quest comparisons valid.
  static Map<String, dynamic> getDailyQuestConfig() {
    final now = DateTime.now();

    // Project to UTC midnight boundaries to guarantee DST-safe day counting.
    final utcNow = DateTime.utc(now.year, now.month, now.day);
    final utcEpoch = DateTime.utc(_epoch.year, _epoch.month, _epoch.day);

    final dayDelta = utcNow.difference(utcEpoch).inDays;

    if (kDebugMode) {
      debugPrint('DailyQuestManager: Day delta since epoch = $dayDelta.');
    }

    final category = _categoryRotation[dayDelta % _categoryRotation.length];
    final level = (dayDelta % _levelRange) + 1;

    return {'category': category, 'level': level};
  }
}
