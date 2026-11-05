import 'package:flutter/foundation.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Single source of truth for leaderboard ranking, deterministic sorting,
/// and real-time rank computation across Home, Leaderboard, and Profile.
@immutable
final class LeaderboardRankingHelper {
  const LeaderboardRankingHelper._();

  /// Sorts users for the All-Time (Global / Hall of Fame) leaderboard:
  /// 1. [totalExp] (primary, descending)
  /// 2. [currentStreak] (tie-breaker, descending)
  /// 3. [totalLevelsCompleted] (tie-breaker, descending)
  ///
  /// Optionally injects or updates [currentUser] with real-time in-session stats.
  static List<UserEntity> sortAllTime(
    List<UserEntity> rawUsers, {
    UserEntity? currentUser,
  }) {
    final list = List<UserEntity>.from(rawUsers);
    if (currentUser != null) {
      final idx = list.indexWhere((u) => u.id == currentUser.id);
      if (idx >= 0) {
        list[idx] = currentUser;
      } else {
        list.add(currentUser);
      }
    }

    list.sort((a, b) {
      if (b.totalExp != a.totalExp) {
        return b.totalExp.compareTo(a.totalExp);
      }
      if (b.currentStreak != a.currentStreak) {
        return b.currentStreak.compareTo(a.currentStreak);
      }
      return b.totalLevelsCompleted.compareTo(a.totalLevelsCompleted);
    });

    return list;
  }

  /// Sorts users for the Weekly League leaderboard:
  /// 1. [currentWeeklyExp] (primary, descending)
  /// 2. [currentStreak] (tie-breaker, descending)
  /// 3. [totalLevelsCompleted] (tie-breaker, descending)
  /// 4. [totalExp] (fallback tie-breaker, descending)
  static List<UserEntity> sortWeekly(
    List<UserEntity> rawUsers, {
    UserEntity? currentUser,
  }) {
    final list = List<UserEntity>.from(rawUsers);
    if (currentUser != null) {
      final idx = list.indexWhere((u) => u.id == currentUser.id);
      if (idx >= 0) {
        list[idx] = currentUser;
      } else {
        list.add(currentUser);
      }
    }

    list.sort((a, b) {
      final aWeekly = a.currentWeeklyExp;
      final bWeekly = b.currentWeeklyExp;
      if (bWeekly != aWeekly) return bWeekly.compareTo(aWeekly);
      if (b.currentStreak != a.currentStreak) {
        return b.currentStreak.compareTo(a.currentStreak);
      }
      if (b.totalLevelsCompleted != a.totalLevelsCompleted) {
        return b.totalLevelsCompleted.compareTo(a.totalLevelsCompleted);
      }
      return b.totalExp.compareTo(a.totalExp);
    });

    return list;
  }

  /// Sorts users for the Kids Zone leaderboard:
  /// 1. [kidsTotalLevelsCompleted] (primary, descending)
  /// 2. [currentStreak] (tie-breaker, descending)
  /// 3. [kidsCoins] (tie-breaker, descending)
  static List<UserEntity> sortKids(
    List<UserEntity> rawUsers, {
    UserEntity? currentUser,
  }) {
    final list = List<UserEntity>.from(rawUsers);
    if (currentUser != null) {
      final idx = list.indexWhere((u) => u.id == currentUser.id);
      if (idx >= 0) {
        list[idx] = currentUser;
      } else {
        list.add(currentUser);
      }
    }

    list.sort((a, b) {
      final aLevels = a.kidsTotalLevelsCompleted;
      final bLevels = b.kidsTotalLevelsCompleted;
      if (bLevels != aLevels) return bLevels.compareTo(aLevels);
      if (b.currentStreak != a.currentStreak) {
        return b.currentStreak.compareTo(a.currentStreak);
      }
      return b.kidsCoins.compareTo(a.kidsCoins);
    });

    return list;
  }

  /// Computes the 1-based rank position of [userId] in [sortedUsers].
  /// Returns `null` if unranked.
  static int? getRankPosition(List<UserEntity> sortedUsers, String? userId) {
    if (userId == null) return null;
    final idx = sortedUsers.indexWhere((u) => u.id == userId);
    return idx >= 0 ? idx + 1 : null;
  }
}

