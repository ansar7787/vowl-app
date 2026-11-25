import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_screen.dart';

/// Typedef / Alias wrapper for the Prefix & Suffix Mastery Phase Screen.
///
/// Ensures backward compatibility with router registrations and phase navigation.
class PrefixSuffixMasteryScreen extends StatelessWidget {
  /// The active curriculum difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Whether this session is running as a mastery bonus stage.
  final bool isBonusStage;

  /// Whether the arcade countdown timer is active.
  final bool enableTimer;

  const PrefixSuffixMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prefixSuffix,
    this.isBonusStage = false,
    this.enableTimer = true,
  });

  @override
  Widget build(BuildContext context) {
    return PrefixSuffixScreen(
      level: level,
      gameType: gameType,
      isBonusStage: isBonusStage,
      enableTimer: enableTimer,
    );
  }
}
