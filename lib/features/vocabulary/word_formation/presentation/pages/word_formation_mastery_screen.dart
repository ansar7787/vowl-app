import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/pages/word_formation_screen.dart';

/// Mastery Phase Screen for Word Formation.
///
/// Executes the comprehensive morphological synthesis evaluation.
/// Stage 1 tests affix injection into the reaction core.
/// Stage 2 presents the optional Bonus XP Arena (+50 XP bonus, 0 hearts deducted for banking).
class WordFormationMasteryScreen extends StatelessWidget {
  final int level;
  final GameSubtype gameType;

  const WordFormationMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordFormation,
  });

  @override
  Widget build(BuildContext context) {
    return WordFormationScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
