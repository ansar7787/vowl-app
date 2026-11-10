import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/toll_gate_bottom_sheet.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Centralized, production-grade helper for Toll Gate milestone validation.
///
/// Toll Gates act as progressive milestone checkpoints for free-tier learners.
/// Premium users automatically bypass all toll gates across the curriculum.
class TollGateHelper {
  const TollGateHelper._();

  /// Determines whether [level] for the given [gameType] is behind an active Toll Gate.
  ///
  /// - Returns `false` if [user] is null or [user.isPremium] is true.
  /// - Returns `true` if [level] is strictly greater than [user.unlockedLevels[gameType]] (defaulting to 1).
  static bool isTollGate({
    required UserEntity? user,
    required String gameType,
    required int level,
  }) {
    if (user == null || user.isPremium) return false;
    final unlocked = user.unlockedLevels[gameType] ?? 1;
    return level > unlocked;
  }

  /// Convenience guard that checks if [level] is behind an active Toll Gate.
  ///
  /// If it is a Toll Gate:
  /// - Automatically presents the official [TollGateBottomSheet].
  /// - Returns `true` (handled / blocked).
  ///
  /// If it is already unlocked or the user is Premium:
  /// - Returns `false` (unblocked, safe to proceed to gameplay).
  static bool handleTollGateIfNeeded({
    required BuildContext context,
    required UserEntity? user,
    required String gameType,
    required int level,
  }) {
    if (isTollGate(user: user, gameType: gameType, level: level)) {
      TollGateBottomSheet.show(
        context: context,
        level: level,
        gameType: gameType,
      );
      return true;
    }
    return false;
  }
}
