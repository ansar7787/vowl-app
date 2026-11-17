import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/pages/academic_word_screen.dart';

/// High-stakes Mastery Phase evaluation screen for Academic Word.
///
/// Stage 1 tests academic register and semantic fit under time constraints.
/// Passing Stage 1 unlocks the victory gate and reveals Stage 2: Bonus XP Arena,
/// featuring the Type-To-Confirm active typing challenge with penalty-free victory banking
/// (+50 XP bonus, 0 hearts deducted for skipping/failing Stage 2).
class AcademicWordMasteryScreen extends StatelessWidget {
  final int level;
  final GameSubtype gameType;

  const AcademicWordMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.academicWord,
  });

  @override
  Widget build(BuildContext context) {
    return AcademicWordScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
