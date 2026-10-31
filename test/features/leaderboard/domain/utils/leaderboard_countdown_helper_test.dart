import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/leaderboard/domain/utils/leaderboard_countdown_helper.dart';

void main() {
  group('LeaderboardCountdownHelper', () {
    test('calculates next 4-hour window from midday', () {
      final time = DateTime.utc(2026, 10, 31, 13, 15); // 13:15 UTC -> next is 16:00 UTC
      final next = LeaderboardCountdownHelper.getNextUpdateTime(time);
      expect(next, DateTime.utc(2026, 10, 31, 16, 0));
      expect(LeaderboardCountdownHelper.getRemainingFormatted(time), '2h 45m');
    });

    test('calculates next 4-hour window when exactly on boundary', () {
      final time = DateTime.utc(2026, 10, 31, 12, 0); // exactly 12:00 UTC -> next is 16:00 UTC
      final next = LeaderboardCountdownHelper.getNextUpdateTime(time);
      expect(next, DateTime.utc(2026, 10, 31, 16, 0));
      expect(LeaderboardCountdownHelper.getRemainingFormatted(time), '4h 0m');
    });

    test('calculates next 4-hour window across midnight into next day', () {
      final time = DateTime.utc(2026, 10, 31, 22, 30); // 22:30 UTC -> next is 00:00 Nov 1 UTC
      final next = LeaderboardCountdownHelper.getNextUpdateTime(time);
      expect(next, DateTime.utc(2026, 11, 1, 0, 0));
      expect(LeaderboardCountdownHelper.getRemainingFormatted(time), '1h 30m');
    });

    test('formats less than 1 hour as minutes only', () {
      final time = DateTime.utc(2026, 10, 31, 15, 42); // 15:42 UTC -> next is 16:00 UTC
      expect(LeaderboardCountdownHelper.getRemainingFormatted(time), '18m');
    });

    test('formats less than 1 minute as < 1m', () {
      final time = DateTime.utc(2026, 10, 31, 15, 59, 30); // 15:59:30 UTC -> next is 16:00 UTC
      expect(LeaderboardCountdownHelper.getRemainingFormatted(time), '< 1m');
    });
  });
}

