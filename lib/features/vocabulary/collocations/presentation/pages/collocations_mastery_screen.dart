import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/pages/collocations_screen.dart';

/// Mastery Phase Screen for Collocations.
///
/// Executes the comprehensive natural pairing evaluation.
/// Stage 1 tests pairing option bubbles into the collocation anchor.
/// Stage 2 presents the optional Bonus XP Arena (+50 XP bonus, 0 hearts deducted for banking).
class CollocationsMasteryScreen extends StatelessWidget {
  final int level;
  final GameSubtype gameType;

  const CollocationsMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.collocations,
  });

  @override
  Widget build(BuildContext context) {
    return CollocationsScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
