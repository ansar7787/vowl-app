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

  /// Calculates ISO-8601 week key (e.g., '2026-W45') for the given [date].
  static String getCurrentWeekKey([DateTime? date]) {
    final now = (date ?? DateTime.now()).toUtc();
    final dayOfYear = int.parse(DateFormat('D').format(now));
    final week = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '${now.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// Calculates previous ISO-8601 week key for the given [date].
  static String getPreviousWeekKey([DateTime? date]) {
    final now = (date ?? DateTime.now()).toUtc();
    final prev = now.subtract(const Duration(days: 7));
    final dayOfYear = int.parse(DateFormat('D').format(prev));
    final week = ((dayOfYear - prev.weekday + 10) / 7).floor();
    return '${prev.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// Checks if [user] finished in top 10 last week and has an unclaimed reward.
  static bool hasUnclaimedReward(UserEntity? user, [DateTime? now]) {
    if (user == null) return false;
    final prevWeekKey = getPreviousWeekKey(now);
    final targetWeekKey = user.previousRankWeekKey ?? prevWeekKey;
    return (user.previousRank != null && user.previousRank! <= 10) &&
        (user.previousRankWeekKey == null ||
            user.previousRankWeekKey == prevWeekKey) &&
        !user.claimedWeeklyRewardWeekKeys.contains(targetWeekKey);
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

    final updatedKeys = [...user.claimedWeeklyRewardWeekKeys, weekKey];
    final coinHistoryEntry = {
      'titleKey': 'coin_history.weekly_league_reward',
      'amount': coins,
      'isEarned': true,
      'timestamp': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
            'claimedWeeklyRewardWeekKeys': updatedKeys,
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

