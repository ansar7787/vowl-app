import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_screen.dart';

/// High-stakes Mastery Phase evaluation screen for Topic Vocab ("Cluster Fusion").
/// Learners fuse thematic word clusters under a dynamic countdown timer with combo multipliers.
class TopicVocabMasteryScreen extends StatelessWidget {
  final int level;
  final GameSubtype gameType;

  const TopicVocabMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.topicVocab,
  });

  @override
  Widget build(BuildContext context) {
    return TopicVocabScreen(
      level: level,
      gameType: gameType,
      isBonusStage: true,
    );
  }
}
