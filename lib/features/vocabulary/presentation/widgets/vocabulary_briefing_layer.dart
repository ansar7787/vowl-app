import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';

class VocabularyBriefingLayer extends StatelessWidget {
  final GameSubtype gameType;
  final int level;
  final dynamic theme;
  final VoidCallback onStart;

  const VocabularyBriefingLayer({
    super.key,
    required this.gameType,
    required this.level,
    required this.theme,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final briefing = GameInstructionService.getBriefing(
      context,
      gameType,
      'Vocabulary',
      level: level,
    );
    return QuestBriefingOverlay(
      title: briefing.title,
      objective: briefing.objective,
      rules: briefing.rules,
      actionText: briefing.actionText,
      tip: briefing.tip,
      icon: briefing.icon,
      primaryColor: theme.primaryColor,
      onStart: onStart,
    );
  }
}
