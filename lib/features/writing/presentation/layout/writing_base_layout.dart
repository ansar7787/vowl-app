import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/layout/game_briefing_scope.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_game_header.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_peeking_mascot.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

/// Base layout container for writing games, providing standard headers, feedback cards, and mascot overlays.
class WritingBaseLayout extends StatelessWidget {
  /// The active writing game subtype.
  final GameSubtype gameType;

  /// Progression level index.
  final int level;

  /// Primary interaction child widget.
  final Widget child;

  /// Whether the current question has been answered.
  final bool isAnswered;

  /// Verification status (`true` if correct, `false` if wrong, `null` if pending).
  final bool? isCorrect;

  /// Callback invoked when the user advances to the next question.
  final VoidCallback onContinue;

  /// Callback invoked when a hint is requested.
  final VoidCallback onHint;

  /// Whether celebration confetti should be triggered.
  final bool showConfetti;

  /// Whether the user failed the question after all allowed retries.
  final bool isFinalFailure;

  /// Whether the scaffold content should be scrollable.
  final bool useScrolling;

  /// Whether standard edge insets should be omitted.
  final bool disablePadding;

  /// Creates a [WritingBaseLayout] instance.
  const WritingBaseLayout({
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
      resizeToAvoidBottomInset: true,
    );

    return GameBaseLayout<WritingBloc, WritingState>(
      config: config,
      stateMapper: (s) => s,
      onRetry: () => context.read<WritingBloc>().add(
        FetchWritingQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () => context.read<WritingBloc>().add(const RestoreLife()),

      headerBuilder: (context, state, progress, lives) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = LevelThemeHelper.getTheme(
          'writing',
          isDark: isDark,
          level: level,
        );
        final currentQuest = state is WritingLoaded
            ? state.currentQuestOrNull
            : null;

        return WritingGameHeader(
          state: state,
          level: level,
          progress: progress,
          lives: lives,
          isAnswered: isAnswered,
          quest: currentQuest,
          theme: theme,
          isDark: isDark,
          soundService: di.sl<SoundService>(),
          onInfoTap: () => GameBriefingScope.show(context),
          onHint: onHint,
        );
      },
      mascotBuilder: (context, state, lives) {
        final theme = LevelThemeHelper.getTheme(
          'writing',
          isDark: Theme.of(context).brightness == Brightness.dark,
          level: level,
        );
        return WritingPeekingMascot(
          state: state,
          lives: lives,
          isCorrect: isCorrect,
          isAnswered: isAnswered,
          theme: theme,
        );
      },
      feedbackBuilder: (context, state) {
        if (state is! WritingLoaded) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = LevelThemeHelper.getTheme(
          'writing',
          isDark: isDark,
          level: level,
        );
        final quest = state.currentQuest;
        final explanation = quest.explanation;
        final ruleContent = quest.context ?? quest.situation ?? explanation;
        final finalExplanation = (ruleContent == explanation)
            ? null
            : explanation;
        final resolvedIsFinalFailure = state.isFinalFailure;

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: resolvedIsFinalFailure,
          livesRemaining: state.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor,
          explanation: finalExplanation,
          ruleTitle: 'WRITING CONTEXT',
          ruleContent: ruleContent,
          sampleAnswer: quest.sampleAnswer ?? quest.correctAnswer,
          requiredPoints: quest.requiredPoints,
        );
      },
    );
  }
}
