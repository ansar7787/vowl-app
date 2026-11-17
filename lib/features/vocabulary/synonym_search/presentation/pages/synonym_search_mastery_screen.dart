import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'synonym_search_screen.dart';

export 'synonym_search_screen.dart';

/// Mastery phase screen for Synonym Search.
///
/// Stage 1 tests rapid synonym identification in the cosmic shard nebula.
/// Stage 2 functions as an optional Bonus XP Arena where composing a sentence earns +25 XP
/// and skipping safely advances to victory without deducting lives.
class SynonymSearchMasteryScreen extends StatelessWidget {
  /// The active difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Creates a [SynonymSearchMasteryScreen] instance.
  const SynonymSearchMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.synonymSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SynonymSearchScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
