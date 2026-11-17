import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_screen.dart';

/// High-stakes Mastery Phase evaluation screen for Idioms.
///
/// Stage 1 serves as the core emoji & dialogue chat decipher assessment.
/// Passing Stage 1 unlocks the victory gate and reveals Stage 2: Bonus XP Arena,
/// featuring the Origin Story breakdown and verbal pronunciation confirmation
/// with penalty-free victory banking (+50 XP bonus).
class IdiomsMasteryScreen extends StatelessWidget {
  final int level;
  final GameSubtype gameType;

  const IdiomsMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.idioms,
  });

  @override
  Widget build(BuildContext context) {
    return IdiomsScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
