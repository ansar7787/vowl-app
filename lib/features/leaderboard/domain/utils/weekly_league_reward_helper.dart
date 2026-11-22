import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/weekly_league_champion_dialog.dart';

/// Centralized utility for weekly league ISO-8601 week calculations,
/// prize tier resolution, and instant 1-tap claim execution.
final class WeeklyLeagueRewardHelper {
  const WeeklyLeagueRewardHelper._();

  /// Calculates ISO-8601 week key (e.g., '2026-W45') matching standard ISO-8601 and Cloud Functions.
  static String getCurrentWeekKey([DateTime? date]) {
    final now = (date ?? DateTime.now()).toUtc();
    final thursday = now.add(Duration(days: 4 - now.weekday));
    final firstDayOfYear = DateTime.utc(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(firstDayOfYear).inDays;
    final weekNumber = ((dayOfYear / 7).floor()) + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Calculates previous ISO-8601 week key matching standard ISO-8601 and Cloud Functions.
  static String getPreviousWeekKey([DateTime? date]) {
    final now = (date ?? DateTime.now()).toUtc();
    return getCurrentWeekKey(now.subtract(const Duration(days: 7)));
  }

  /// Returns the exact Monday (00:00:00.000 UTC) for a given ISO-8601 week key (e.g. '2026-W45').
  static DateTime getMondayForWeekKey(String? weekKey, [DateTime? referenceDate]) {
    if (weekKey != null && RegExp(r'^\d{4}-W\d{2}$').hasMatch(weekKey)) {
      final parts = weekKey.split('-W');
      final year = int.parse(parts[0]);
      final week = int.parse(parts[1]);

      // Jan 4th is always in week 1 of ISO 8601
      final jan4 = DateTime.utc(year, 1, 4);
      final jan4Weekday = jan4.weekday; // 1 = Monday, 7 = Sunday
      final week1Monday = jan4.subtract(Duration(days: jan4Weekday - 1));
      return week1Monday.add(Duration(days: (week - 1) * 7));
    }
    final now = (referenceDate ?? DateTime.now()).toUtc();
    final daysSinceMonday = (now.weekday - 1) % 7;
    return DateTime.utc(now.year, now.month, now.day)
        .subtract(Duration(days: daysSinceMonday + 7));
  }

  /// Calculates the exact XP earned by [user] during the 7 days (Monday through Sunday)
  /// of the target [weekKey].
  static int getWeeklyExpForWeek(UserEntity user, String? weekKey) {
    if (weekKey != null && user.dailyXpHistory.isNotEmpty) {
      final monday = getMondayForWeekKey(weekKey);
      var sum = 0;
      bool hasDateMatch = false;
      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        final dayKey =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        if (user.dailyXpHistory.containsKey(dayKey)) {
          hasDateMatch = true;
          sum += user.dailyXpHistory[dayKey] ?? 0;
        }
      }
      if (hasDateMatch || sum > 0) {
        return sum;
      }
    }

    final prevWeekKey = getPreviousWeekKey();
    final curWeekKey = getCurrentWeekKey();
    if (weekKey == prevWeekKey && user.previousWeeklyExp > 0) {
      return user.previousWeeklyExp;
    }
    if (weekKey == curWeekKey && user.currentWeeklyExp > 0) {
      return user.currentWeeklyExp;
    }
    return 0;
  }

  /// Formats human-readable exact start and end date for a week key (e.g., 'Nov 2 – Nov 8, 2026').
  static String formatWeekDateRange(
    String? weekKey, {
    DateTime? referenceDate,
    String? locale,
  }) {
    final monday = getMondayForWeekKey(weekKey, referenceDate);
    final sunday = monday.add(const Duration(days: 6));

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final mMonth = months[monday.month - 1];
    final sMonth = months[sunday.month - 1];

    if (locale != null && locale.isNotEmpty && !locale.startsWith('en')) {
      try {
        if (monday.year == sunday.year) {
          return '${DateFormat('MMM d', locale).format(monday)} – ${DateFormat('MMM d, yyyy', locale).format(sunday)}';
        } else {
          return '${DateFormat('MMM d, yyyy', locale).format(monday)} – ${DateFormat('MMM d, yyyy', locale).format(sunday)}';
        }
      } catch (_) {
        // Fall back to clean deterministic date formatting
      }
    }

    if (monday.year == sunday.year) {
      return '$mMonth ${monday.day} – $sMonth ${sunday.day}, ${sunday.year}';
    } else {
      return '$mMonth ${monday.day}, ${monday.year} – $sMonth ${sunday.day}, ${sunday.year}';
    }
  }

  /// Returns the relevant week key for claiming the reward.
  static String getTargetWeekKey(UserEntity? user, [DateTime? now]) {
    return user?.previousRankWeekKey ?? getPreviousWeekKey(now);
  }

  /// Checks if [user] finished in top 10 and has an unclaimed reward.
  /// Validates that the reward is from the immediately completed league cycle
  /// (either current week or previous week to seamlessly bridge Sunday reset and Monday rollout)
  /// and has not yet been claimed.
  static bool hasUnclaimedReward(UserEntity? user, [DateTime? now]) {
    if (user == null) return false;
    final rank = user.previousRank;
    if (rank == null || rank < 1 || rank > 10) return false;

    final prevWeekKey = getPreviousWeekKey(now);
    final curWeekKey = getCurrentWeekKey(now);
    final targetWeekKey = getTargetWeekKey(user, now);

    final isEligibleWeek = user.previousRankWeekKey == null ||
        user.previousRankWeekKey == prevWeekKey ||
        user.previousRankWeekKey == curWeekKey;

    if (!isEligibleWeek) return false;

    return !user.claimedWeeklyRewardWeekKeys.contains(targetWeekKey);
  }

  /// Resolves VIP trial days for [rank].
  static int getVipDays(int rank) {
    if (rank == 1) return 7;
    if (rank == 2) return 3;
    if (rank == 3) return 1;
    return 0;
  }

  /// Resolves bonus coin amount for [rank].
  static int getCoins(int rank) {
    if (rank == 1) return 500;
    if (rank == 2) return 300;
    if (rank == 3) return 200;
    if (rank <= 10) return 100;
    return 0;
  }

  /// Returns prominent honorific title for [rank].
  static String getRankTitle(int rank) {
    if (rank == 1) return 'Weekly League Champion';
    if (rank == 2) return 'Weekly Silver Runner-Up';
    if (rank == 3) return 'Weekly Bronze Podium';
    return 'Weekly Top 10 Finisher';
  }

  /// Returns exact winner placement subtitle for [rank].
  static String getRankSubtitle(int rank) {
    if (rank == 1) return '1st Place Winner';
    if (rank == 2) return '2nd Place Winner';
    if (rank == 3) return '3rd Place Winner';
    return 'Rank #$rank Winner';
  }

  /// Returns a concise prize description string (e.g., '7d VIP & 500 Coins').
  static String getPrizeSummary(int rank) {
    final vip = getVipDays(rank);
    final coins = getCoins(rank);
    if (vip > 0 && coins > 0) {
      return '${vip}d VIP & $coins Coins';
    }
    if (coins > 0) {
      return '$coins Coins';
    }
    if (vip > 0) {
      return '${vip}d VIP';
    }
    return 'League Badge';
  }

  /// Executes atomic 1-tap claim:
  /// 1. Updates user coins, premium status, and claimed keys in Firestore.
  /// 2. Plays coin tally sound and triggers success haptic.
  /// 3. Refreshes local AuthBloc user state.
  /// 4. Pops up the celebration dialog with confetti burst and 'Got It!' button.
  static Future<bool> claimReward({
    required BuildContext context,
    required UserEntity user,
    required int rank,
    required int vipDays,
    required int coins,
    required String weekKey,
    bool showCelebrationDialog = true,
  }) async {
    // Prevent duplicate claim submissions
    if (user.claimedWeeklyRewardWeekKeys.contains(weekKey)) {
      return true;
    }

    final now = DateTime.now();
    final DateTime? newExpiry;
    if (vipDays > 0) {
      if (user.isPremium &&
          user.premiumExpiryDate != null &&
          user.premiumExpiryDate!.isAfter(now)) {
        newExpiry = user.premiumExpiryDate!.add(Duration(days: vipDays));
      } else {
        newExpiry = now.add(Duration(days: vipDays));
      }
    } else {
      newExpiry = null;
    }

    final coinHistoryEntry = {
      'titleKey': 'coin_history.weekly_league_reward',
      'amount': coins,
      'isEarned': true,
      'date': DateTime.now().toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
            'claimedWeeklyRewardWeekKeys': FieldValue.arrayUnion([weekKey]),
            if (coins > 0) ...{
              'coins': FieldValue.increment(coins),
              'coinHistory': FieldValue.arrayUnion([coinHistoryEntry]),
            },
            if (vipDays > 0) ...{
              'isPremium': true,
              'premiumExpiryDate': Timestamp.fromDate(newExpiry!),
            },
            'lastRewardTimestamp': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().success();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playCoinTally(count: 8);
        }

        context.read<AuthBloc>().add(const AuthRefreshUser());
        context.read<AuthBloc>().add(const AuthReloadUser());

        if (showCelebrationDialog) {
          WeeklyLeagueChampionDialog.show(
            context: context,
            user: user,
            rank: rank,
            vipDays: vipDays,
            coins: coins,
            weekKey: weekKey,
            isAlreadyClaimed: true,
          );
        }

        CustomSnackBar.show(
          context: context,
          message: vipDays > 0
              ? 'Reward Claimed! Enjoy your $vipDays day${vipDays > 1 ? "s" : ""} VIP & $coins coins.'
              : 'Reward Claimed! Enjoy your $coins coins.',
          type: CustomSnackBarType.success,
        );
      }
      return true;
    } catch (e) {
      debugPrint('[WeeklyLeagueRewardHelper] claimReward error: $e');
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to claim reward. Please check your connection.',
          type: CustomSnackBarType.error,
        );
      }
      return false;
    }
  }
}

