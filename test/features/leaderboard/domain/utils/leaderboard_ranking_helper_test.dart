import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/utils/leaderboard_ranking_helper.dart';

void main() {
  final todayKey = DateTime.now().toIso8601String().substring(0, 10);

  final userA = UserEntity(
    id: 'user_a',
    email: 'a@vowl.app',
    displayName: 'User A',
    totalExp: 5000,
    dailyXpHistory: {todayKey: 1000},
    currentStreak: 10,
    completedLevels: {
      'reading': List.generate(20, (i) => i + 1),
      'animals': List.generate(5, (i) => i + 1),
    },
    starRatings: {
      'animals': {'1': 3},
    },
  );

  final userB = UserEntity(
    id: 'user_b',
    email: 'b@vowl.app',
    displayName: 'User B',
    totalExp: 8000,
    dailyXpHistory: {todayKey: 2000},
    currentStreak: 5,
    completedLevels: {
      'reading': List.generate(30, (i) => i + 1),
      'animals': List.generate(10, (i) => i + 1),
    },
    starRatings: {
      'animals': {'1': 3, '2': 3},
    },
  );

  final userC = UserEntity(
    id: 'user_c',
    email: 'c@vowl.app',
    displayName: 'User C',
    totalExp: 8000,
    dailyXpHistory: {todayKey: 2000},
    currentStreak: 15, // Higher streak tie-breaker
    completedLevels: {
      'reading': List.generate(25, (i) => i + 1),
      'animals': List.generate(10, (i) => i + 1),
    },
    starRatings: {
      'animals': {'1': 3, '2': 3, '3': 3},
    },
  );

  group('LeaderboardRankingHelper.sortAllTime', () {
    test('sorts by totalExp descending and resolves ties via streak', () {
      final sorted = LeaderboardRankingHelper.sortAllTime([
        userA,
        userB,
        userC,
      ]);
      expect(sorted.length, 3);
      expect(sorted[0].id, 'user_c'); // 8000 XP, 15 streak
      expect(sorted[1].id, 'user_b'); // 8000 XP, 5 streak
      expect(sorted[2].id, 'user_a'); // 5000 XP
    });

    test('injects current user into list if not present', () {
      final currentUser = UserEntity(
        id: 'me',
        email: 'me@vowl.app',
        totalExp: 10000,
      );
      final sorted = LeaderboardRankingHelper.sortAllTime([
        userA,
        userB,
      ], currentUser: currentUser);
      expect(sorted.length, 3);
      expect(sorted[0].id, 'me');
    });

    test('updates current user in list if already present', () {
      final updatedUserA = userA.copyWith(totalExp: 12000);
      final sorted = LeaderboardRankingHelper.sortAllTime([
        userA,
        userB,
      ], currentUser: updatedUserA);
      expect(sorted.length, 2);
      expect(sorted[0].id, 'user_a');
      expect(sorted[0].totalExp, 12000);
    });
  });

  group('LeaderboardRankingHelper.sortWeekly', () {
    test('sorts by weekly XP descending and resolves ties via streak', () {
      final sorted = LeaderboardRankingHelper.sortWeekly([userA, userB, userC]);
      expect(sorted[0].id, 'user_c'); // 2000 weekly, 15 streak
      expect(sorted[1].id, 'user_b'); // 2000 weekly, 5 streak
      expect(sorted[2].id, 'user_a'); // 1000 weekly
    });
  });

  group('LeaderboardRankingHelper.getRankPosition', () {
    test('returns exact 1-based rank when user is found', () {
      final sorted = [userC, userB, userA];
      expect(LeaderboardRankingHelper.getRankPosition(sorted, 'user_c'), 1);
      expect(LeaderboardRankingHelper.getRankPosition(sorted, 'user_b'), 2);
      expect(LeaderboardRankingHelper.getRankPosition(sorted, 'user_a'), 3);
    });

    test('returns null when user is not found or id is null', () {
      final sorted = [userC, userB, userA];
      expect(
        LeaderboardRankingHelper.getRankPosition(sorted, 'unknown'),
        isNull,
      );
      expect(LeaderboardRankingHelper.getRankPosition(sorted, null), isNull);
    });
  });
}
