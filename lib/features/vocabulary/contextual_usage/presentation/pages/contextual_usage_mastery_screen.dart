import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/pages/contextual_usage_screen.dart';

/// Mastery Phase Screen for Contextual Usage.
///
/// Executes the comprehensive contextual and register fitness evaluation.
/// Stage 1 tests selecting the precise word that fits tone, register, and agent orientation.
/// Stage 2 presents the optional Bonus XP Arena (+50 XP bonus, 0 hearts deducted for banking).
class ContextualUsageMasteryScreen extends StatelessWidget {
  final int level;
  final GameSubtype gameType;

  const ContextualUsageMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextualUsage,
  });

  @override
  Widget build(BuildContext context) {
    return ContextualUsageScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
