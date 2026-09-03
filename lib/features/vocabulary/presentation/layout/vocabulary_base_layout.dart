import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_header.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_peeking_mascot.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/vocabulary/presentation/themes/vocab_level_theme.dart';
import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_vocab_mind_map.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_family_tree.dart';

class VocabularyBaseLayout extends StatelessWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final bool isFinalFailure;
  final VoidCallback onContinue;
  final VoidCallback? onHint;
  final bool showConfetti;
  final bool useScrolling;
  final bool disablePadding;
  final String? customHintText;
  final bool hasStage2;

  const VocabularyBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.isCorrect,
    this.isFinalFailure = false,
    required this.onContinue,
    this.onHint,
    this.showConfetti = false,
    this.useScrolling = false,
    this.disablePadding = false,
    this.customHintText,
    this.hasStage2 = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = GameScaffoldConfig(
      gameType: gameType,
      level: level,
      child: child,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      isFinalFailure: isFinalFailure,
      onContinue: onContinue,
      onHint: onHint,
      showConfetti: showConfetti,
      useScrolling: useScrolling,
      disablePadding: disablePadding,
    );

    return GameBaseLayout<VocabularyBloc, VocabularyState>(
      config: config,
      stateMapper: (state) => state,
      onRetry: () => context.read<VocabularyBloc>().add(
        FetchVocabularyQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () =>
          context.read<VocabularyBloc>().add(const RestoreLife()),
      headerBuilder: (context, state, progress, lives) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = VocabLevelTheme.from(
          LevelThemeHelper.getTheme(
            gameType.name,
            isDark: isDark,
            level: level,
          ),
        );
        return VocabularyHeader(
          state: state,
          level: level,
          progress: progress,
          lives: lives,
          theme: theme,
          isDark: isDark,
          isAnswered: isAnswered,
          gameType: gameType,
          onExit: () => GameDialogHelper.showExitConfirmation(
            context,
            onQuit: () => Navigator.of(context).pop(),
          ),
          onBriefingShow: () {}, // Handled by GameBaseLayout internally now
          onHint: onHint,
          customHintText: customHintText,
        );
      },
      mascotBuilder: (context, state, lives) {
        return VocabularyPeekingMascot(
          state: state,
          lives: lives,
          isCorrect: isCorrect,
          isAnswered: isAnswered,
        );
      },
      feedbackBuilder: (context, state) {
        if (state is! VocabularyLoaded) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = VocabLevelTheme.from(
          LevelThemeHelper.getTheme(
            gameType.name,
            isDark: isDark,
            level: level,
          ),
        );

        final quest = state.currentQuest;
        String? explanation = quest.explanation;
        final resolvedIsFinalFailure = state.isFinalFailure;
        if (explanation == null &&
            isCorrect == false &&
            resolvedIsFinalFailure) {
          if (quest.correctAnswerIndex != null &&
              quest.options != null &&
              quest.options!.isNotEmpty) {
            explanation = quest.options![quest.correctAnswerIndex!];
          }
        }

        String? ruleContent = quest.definition ?? explanation;
        String? finalExplanation = (ruleContent == explanation)
            ? null
            : explanation;
        String ruleTitle = 'VOCABULARY TIP';
        Widget? customContent;

        if (gameType == GameSubtype.topicVocab) {
          if (quest.relatedWords != null && quest.relatedWords!.isNotEmpty) {
            customContent = TopicVocabMindMap(
              relatedWords: quest.relatedWords!,
              color: isCorrect == true
                  ? const Color(0xFF10B981)
                  : theme.primaryColor,
            );
          }
          ruleTitle = '';
          ruleContent = null;
          finalExplanation = quest.explanation;
        } else if (gameType == GameSubtype.wordFormation) {
          ruleTitle = 'WORD BUILDING';
          if (quest.familyTree != null && quest.familyTree!.isNotEmpty) {
            customContent = WordFormationFamilyTree(
              familyTree: quest.familyTree!,
              color: isCorrect == true
                  ? const Color(0xFF10B981)
                  : theme.primaryColor,
            );
          }
        } else if (gameType == GameSubtype.prefixSuffix) {
          ruleTitle = 'WORD BREAKDOWN';
          if (quest.meaningBreakdown != null) {
            ruleContent = quest.meaningBreakdown;
            finalExplanation = quest.explanation;
          }
        }

        if (hasStage2) {
          ruleContent = null;
          finalExplanation = quest.explanation ?? quest.definition;
        }

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: resolvedIsFinalFailure,
          livesRemaining: state.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor,
          explanation: finalExplanation,
          ruleTitle: ruleTitle,
          ruleContent: ruleContent,
          customContent: customContent,
          isTwoStageGame: hasStage2,
        );
      },
    );
  }
}
