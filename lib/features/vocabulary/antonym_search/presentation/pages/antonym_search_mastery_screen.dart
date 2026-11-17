import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'antonym_search_screen.dart';

export 'antonym_search_screen.dart';

/// Mastery phase screen for Antonym Search.
///
/// Stage 1 tests rapid polar opposite identification in the cosmic shard nebula.
/// Stage 2 functions as an optional Bonus XP Arena where pronouncing the antonym pair earns +25 XP
/// and skipping safely advances to victory without deducting lives.
class AntonymSearchMasteryScreen extends StatelessWidget {
  /// The active difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Creates an [AntonymSearchMasteryScreen] instance.
  const AntonymSearchMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.antonymSearch,
  });

  @override
  Widget build(BuildContext context) {
    return AntonymSearchScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
