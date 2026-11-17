import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_screen.dart';

/// Mastery Phase Screen for Prefix Suffix.
///
/// Executes the comprehensive affix synthesis evaluation.
/// Stage 1 tests prefix/suffix slot placement into base roots.
/// Stage 2 presents the optional Bonus XP Arena (+50 XP bonus, 0 hearts deducted for banking).
class PrefixSuffixMasteryScreen extends StatelessWidget {
  final int level;
  final GameSubtype gameType;

  const PrefixSuffixMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prefixSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return PrefixSuffixScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
