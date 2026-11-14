import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';

import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/games/headers/vowl_universal_game_header.dart';
import 'package:vowl/core/presentation/widgets/games/dialogs/vowl_pause_bottom_sheet.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_peeking_mascot.dart';

import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/layout/game_briefing_scope.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

/// Scaffold shell providing background styling, header HUD, peeking mascot, and feedback drawers for grammar subgames.
class GrammarBaseLayout extends StatelessWidget {
  /// The specific grammar subtype.
  final GameSubtype gameType;

  /// The active level index.
  final int level;

  /// The question-specific child widget tree.
  final Widget child;

  /// Whether the trial has been submitted.
  final bool isAnswered;

  /// Evaluation outcome of the answer (`null` if unanswered).
  final bool? isCorrect;

  /// Callback executed when tapping continue on the feedback drawer.
  final VoidCallback onContinue;

  /// Callback executed when the hint button is pressed.
  final VoidCallback onHint;

  /// Whether victory confetti should be displayed.
  final bool showConfetti;

  /// Whether this is the final failure on the question (triggering mastery loop).
  final bool isFinalFailure;

  /// Whether the content area should be wrapped in a scroll view.
  final bool useScrolling;

  /// Whether default layout padding should be suppressed.
  final bool disablePadding;

  /// Creates a [GrammarBaseLayout] widget.
  const GrammarBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.isCorrect,
    this.isFinalFailure = false,
    required this.onContinue,
    required this.onHint,
    this.showConfetti = false,
    this.useScrolling = false,
    this.disablePadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      horizontalPadding: AppSpacing.compact,
    );

    return GameBaseLayout<GrammarBloc, GrammarState>(
      config: config,
      stateMapper: (state) => state,

      onRetry: () => context.read<GrammarBloc>().add(
        FetchGrammarQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () => context.read<GrammarBloc>().add(const RestoreLife()),
      headerBuilder: (context, state, progress, lives) {
        final isLoaded = state is GrammarLoaded;
        final currentQuest = isLoaded ? state.currentQuestOrNull : null;
        final hintShouldBeEnabled = currentQuest != null && !isAnswered;
        final isHintUsed = isLoaded ? state.hintUsed : false;

        return VowlUniversalGameHeader(
          level: level,
          category: 'grammar',
          progress: progress,
          lives: lives,
          hintText: currentQuest?.hint,
          isHintUsedOnCurrentQuest: isHintUsed,
          isHintEnabled: hintShouldBeEnabled,
          onPause: () {
            VowlPauseBottomSheet.show(
              context,
              category: 'grammar',
              onResume: () {},
              onRestart: () {
                context.read<GrammarBloc>().add(
                  FetchGrammarQuests(gameType: gameType, level: level),
                );
              },
              onQuit: () => Navigator.of(context).pop(),
            );
          },
          onBriefing: () => GameBriefingScope.show(context),
          onHint: () {
            context.read<GrammarBloc>().add(const GrammarHintUsed());
            onHint();
          },
        );
      },
      mascotBuilder: (context, state, lives) {
        final mascotId =
            context.read<AuthBloc>().state.user?.vowlMascot ?? 'vowl_prime';
        return GrammarPeekingMascot(
          state: state,
          lives: lives,
          isCorrect: isCorrect,
          isAnswered: isAnswered,
          mascotId: mascotId,
        );
      },
      feedbackBuilder: (context, state) {
        if (state is! GrammarLoaded) return const SizedBox.shrink();
        final theme = LevelThemeHelper.of(context, 'grammar', level: level);

        final quest = state.currentQuest;
        String? explanation = quest.explanation;
        final resolvedIsFinalFailure = state.isFinalFailure;
        if (explanation == null &&
            isCorrect == false &&
            resolvedIsFinalFailure) {
          explanation =
              (quest.options != null && quest.correctAnswerIndex != null
              ? quest.options![quest.correctAnswerIndex!]
              : null);
        }

        final ruleContent = quest.grammarRule ?? explanation;
        final finalExplanation = (ruleContent == explanation)
            ? null
            : explanation;

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: resolvedIsFinalFailure,
          livesRemaining: state.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor,
          explanation: finalExplanation,
          ruleTitle: 'GRAMMAR RULE',
          ruleContent: ruleContent,
        );
      },
    );
  }
}
