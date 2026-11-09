import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/utils/weekly_league_reward_helper.dart';

void main() {
  group('WeeklyLeagueRewardHelper', () {
    test('calculates current and previous week keys deterministically', () {
      final wednesday = DateTime.utc(2026, 11, 4); // ISO week 45 of 2026
      expect(
        WeeklyLeagueRewardHelper.getCurrentWeekKey(wednesday),
        equals('2026-W45'),
      );
      expect(
        WeeklyLeagueRewardHelper.getPreviousWeekKey(wednesday),
        equals('2026-W44'),
      );
    });

    test('correctly evaluates hasUnclaimedReward', () {
      final now = DateTime.utc(2026, 11, 4);
      final prevWeek = WeeklyLeagueRewardHelper.getPreviousWeekKey(now);

      const winnerUnclaimed = UserEntity(
        id: 'u1',
        email: 'u1@vowl.app',
        displayName: 'Winner',
        previousRank: 1,
        previousRankWeekKey: '2026-W44',
        claimedWeeklyRewardWeekKeys: [],
      );
      expect(
        WeeklyLeagueRewardHelper.hasUnclaimedReward(winnerUnclaimed, now),
        isTrue,
      );

      const winnerAlreadyClaimed = UserEntity(
        id: 'u2',
        email: 'u2@vowl.app',
        displayName: 'Claimed Winner',
        previousRank: 1,
        previousRankWeekKey: '2026-W44',
        claimedWeeklyRewardWeekKeys: ['2026-W44'],
      );
      expect(
        WeeklyLeagueRewardHelper.hasUnclaimedReward(winnerAlreadyClaimed, now),
        isFalse,
      );

      const notTopTen = UserEntity(
        id: 'u3',
        email: 'u3@vowl.app',
        displayName: 'Participant',
        previousRank: 15,
        previousRankWeekKey: '2026-W44',
        claimedWeeklyRewardWeekKeys: [],
      );
      expect(
        WeeklyLeagueRewardHelper.hasUnclaimedReward(notTopTen, now),
        isFalse,
      );

      const expiredWeek = UserEntity(
        id: 'u4',
        email: 'u4@vowl.app',
        displayName: 'Expired Winner',
        previousRank: 1,
        previousRankWeekKey: '2026-W40', // Expired week
        claimedWeeklyRewardWeekKeys: [],
      );
      expect(
        WeeklyLeagueRewardHelper.hasUnclaimedReward(expiredWeek, now),
        isFalse,
      );
    });

    test('allocates VIP days and coins strictly according to tier', () {
      expect(WeeklyLeagueRewardHelper.getVipDays(1), 7);
      expect(WeeklyLeagueRewardHelper.getCoins(1), 500);

      expect(WeeklyLeagueRewardHelper.getVipDays(2), 3);
      expect(WeeklyLeagueRewardHelper.getCoins(2), 300);

      expect(WeeklyLeagueRewardHelper.getVipDays(3), 1);
      expect(WeeklyLeagueRewardHelper.getCoins(3), 200);

      for (var r = 4; r <= 10; r++) {
        expect(WeeklyLeagueRewardHelper.getVipDays(r), 0);
        expect(WeeklyLeagueRewardHelper.getCoins(r), 100);
      }
    });

    test('provides distinct honorific winner titles and subtitles', () {
      expect(
        WeeklyLeagueRewardHelper.getRankTitle(1),
        'Weekly League Champion',
      );
      expect(
        WeeklyLeagueRewardHelper.getRankSubtitle(1),
        '1st Place Winner',
      );
      expect(
        WeeklyLeagueRewardHelper.getPrizeSummary(1),
        '7d VIP & 500 Coins',
      );

      expect(
        WeeklyLeagueRewardHelper.getRankTitle(2),
        'Weekly Silver Runner-Up',
      );
      expect(
        WeeklyLeagueRewardHelper.getRankSubtitle(2),
        '2nd Place Winner',
      );
      expect(
        WeeklyLeagueRewardHelper.getPrizeSummary(2),
        '3d VIP & 300 Coins',
      );

      expect(
        WeeklyLeagueRewardHelper.getRankTitle(3),
        'Weekly Bronze Podium',
      );
      expect(
        WeeklyLeagueRewardHelper.getRankSubtitle(3),
        '3rd Place Winner',
      );
      expect(
        WeeklyLeagueRewardHelper.getPrizeSummary(3),
        '1d VIP & 200 Coins',
      );

      expect(
        WeeklyLeagueRewardHelper.getRankTitle(5),
        'Weekly Top 10 Finisher',
      );
      expect(
        WeeklyLeagueRewardHelper.getRankSubtitle(5),
        'Rank #5 Winner',
      );
      expect(
        WeeklyLeagueRewardHelper.getPrizeSummary(5),
        '100 Coins',
      );
    });
  });
}

