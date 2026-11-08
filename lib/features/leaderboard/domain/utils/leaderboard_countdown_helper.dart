import 'package:flutter/foundation.dart';

/// Utility to calculate and format the countdown to the next scheduled
/// leaderboard cache update (which runs every 4 hours at 00:00, 04:00, 08:00,
/// 12:00, 16:00, 20:00 UTC).
@immutable
final class LeaderboardCountdownHelper {
  const LeaderboardCountdownHelper._();

  /// Calculates the exact [DateTime] in UTC of the next 4-hour scheduled update.
  static DateTime getNextUpdateTime([DateTime? fromTime]) {
    final now = (fromTime ?? DateTime.now()).toUtc();
    final currentHour = now.hour;
    final nextHour = ((currentHour ~/ 4) + 1) * 4;
    if (nextHour >= 24) {
      return DateTime.utc(now.year, now.month, now.day + 1, 0, 0, 0);
    }
    return DateTime.utc(now.year, now.month, now.day, nextHour, 0, 0);
  }

  /// Returns a clean human-readable duration string to the next update
  /// (e.g., "2h 45m", "35m", or "< 1m").
  static String getRemainingFormatted([DateTime? fromTime]) {
    final now = (fromTime ?? DateTime.now()).toUtc();
    final next = getNextUpdateTime(now);
    final diff = next.difference(now);
    if (diff.isNegative) return '< 1m';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m';
    }
    return '< 1m';
  }
}
