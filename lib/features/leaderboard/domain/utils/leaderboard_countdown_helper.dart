import 'package:flutter/foundation.dart';

/// Utility to calculate and format the countdown to the next scheduled
/// leaderboard cache update.
///
/// Production Cloud Functions recalculate cache hourly ('0 * * * *') at the top
/// of every hour (00:00, 01:00, 02:00, ..., 23:00 UTC).
@immutable
final class LeaderboardCountdownHelper {
  const LeaderboardCountdownHelper._();

  /// Calculates the exact [DateTime] in UTC of the next scheduled cache update.
  /// Defaults to hourly (`intervalHours = 1`) matching production Cloud Functions.
  static DateTime getNextUpdateTime([
    DateTime? fromTime,
    int intervalHours = 1,
  ]) {
    final now = (fromTime ?? DateTime.now()).toUtc();
    if (intervalHours <= 1) {
      final nextHourDate = now.add(const Duration(hours: 1));
      return DateTime.utc(
        nextHourDate.year,
        nextHourDate.month,
        nextHourDate.day,
        nextHourDate.hour,
        0,
        0,
      );
    }
    final currentHour = now.hour;
    final nextHour = ((currentHour ~/ intervalHours) + 1) * intervalHours;
    if (nextHour >= 24) {
      final nextDay = now.add(const Duration(days: 1));
      return DateTime.utc(nextDay.year, nextDay.month, nextDay.day, 0, 0, 0);
    }
    return DateTime.utc(now.year, now.month, now.day, nextHour, 0, 0);
  }

  /// Returns a clean human-readable duration string to the next update
  /// (e.g., "45m", "18m", or "< 1m" for hourly; "2h 45m" for multi-hour).
  static String getRemainingFormatted([
    DateTime? fromTime,
    int intervalHours = 1,
  ]) {
    final now = (fromTime ?? DateTime.now()).toUtc();
    final next = getNextUpdateTime(now, intervalHours);
    final diff = next.difference(now);
    if (diff.isNegative) return '< 1m';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h 0m';
    }
    if (minutes > 0) {
      return '${minutes}m';
    }
    return '< 1m';
  }
}
