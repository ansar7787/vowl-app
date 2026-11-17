import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'context_clues_screen.dart';

export 'context_clues_screen.dart';

/// Mastery phase screen for Context Clues.
///
/// Stage 1 tests rapid word deduction via forensic detective lens and evidence tags.
/// Stage 2 functions as an optional Bonus XP Arena where highlighting supporting clue words earns +25 XP
/// and skipping safely advances to victory without deducting lives.
class ContextCluesMasteryScreen extends StatelessWidget {
  /// The active difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Creates a [ContextCluesMasteryScreen] instance.
  const ContextCluesMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextClues,
  });

  @override
  Widget build(BuildContext context) {
    return ContextCluesScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
