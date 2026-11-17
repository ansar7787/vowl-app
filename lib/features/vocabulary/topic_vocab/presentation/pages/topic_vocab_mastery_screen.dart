import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_screen.dart';

/// High-stakes Mastery Phase evaluation screen for Topic Vocab.
///
/// Stage 1 tests rapid semantic categorization and containment sorting under time constraints.
/// Passing Stage 1 unlocks the victory gate and reveals Stage 2: Bonus XP Arena,
/// featuring the Topic Vocabulary Mind Map with penalty-free victory banking (+50 XP bonus).
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
