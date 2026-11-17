import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'phrasal_verbs_screen.dart';

export 'phrasal_verbs_screen.dart';

/// Mastery phase screen for Phrasal Verbs: "Particle Vault Arena".
///
/// Stage 1 tests rapid particle recognition by turning the central vault handle to unlock the safe.
/// Stage 2 functions as an optional Bonus XP Arena where assembling the context sentence earns +50 XP
/// and skipping safely banks the core win without deducting lives.
class PhrasalVerbsMasteryScreen extends StatelessWidget {
  /// The active difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Creates a [PhrasalVerbsMasteryScreen] instance.
  const PhrasalVerbsMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.phrasalVerbs,
  });

  @override
  Widget build(BuildContext context) {
    return PhrasalVerbsScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
