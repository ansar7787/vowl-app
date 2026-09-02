import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_content_area.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_header.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_passage_area.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';

import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

class ReadingBaseLayout extends StatelessWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final bool isFinalFailure;
  final String? passage;
  final bool useScrolling;
  final bool disablePadding;
  final bool hasStage2;

  const ReadingBaseLayout({
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
    this.passage,
    this.useScrolling = false,
    this.disablePadding = false,
    this.hasStage2 = false,
  });

  @override
  Widget build(BuildContext context) {
    final mascotId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.vowlMascot ?? 'vowl_prime',
    );
    final mascotName = mascotId
        .split('_')
        .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');

    return BlocBuilder<ReadingBloc, ReadingState>(
      // We wrap GameBaseLayout with BlocBuilder just to get the current state
      // for the child wrapper (ReadingContentArea needs to know if it's over/complete).
      // Wait, GameScaffoldConfig is rebuilt on state changes anyway because GameBaseLayout builds internally.
      // But we can just use the state from the BlocProvider directly without the builder if we extract the config inside.
      builder: (context, state) {
        final isComplete = state is ReadingGameComplete;
        final isGameOver = state is ReadingGameOver;
        final lives = state.livesRemaining;

        final wrappedChild = ReadingContentArea(
          isAnswered: isAnswered,
          useScrolling: useScrolling,
          disablePadding: disablePadding,
          lives: lives,
          isCorrect: isCorrect,
          isGameComplete: isComplete,
          isGameOver: isGameOver,
          mascotId: mascotId,
          mascotName: mascotName,
          child: child,
        );

        final config = GameScaffoldConfig(
          gameType: gameType,
          level: level,
          child: wrappedChild, // Use the wrapped child!
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          onContinue: onContinue,
          onHint: onHint,
          showConfetti: showConfetti,
          useScrolling: false, // ReadingContentArea handles scrolling
          disablePadding: true, // ReadingContentArea handles padding
        );

        return GameBaseLayout<ReadingBloc, ReadingState>(
          config: config,
          stateMapper: (s) => s,
          onRetry: () => context.read<ReadingBloc>().add(
            FetchReadingQuests(gameType: gameType, level: level),
          ),
          onRestoreLife: () =>
              context.read<ReadingBloc>().add(const RestoreLife()),
          headerBuilder: (context, s, progress, lvs) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final theme = LevelThemeHelper.getTheme(
              gameType.name,
              isDark: isDark,
              level: level,
            );

            final gameProgressHeader = GameProgressHeader(
              level: level,
              progress: progress,
              lives: lvs,
              theme: theme,
              isDark: isDark,
              onBack: () => GameDialogHelper.showExitConfirmation(
                context,
                onQuit: () => Navigator.of(context).pop(),
              ),
            );

            final currentQuest = s is ReadingLoaded ? s.currentQuest : null;
            final hintUsed = s is ReadingLoaded ? s.hintUsed : false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReadingHeader(
                  gameProgressHeader: gameProgressHeader,
                  primaryColor: theme.primaryColor,
                  currentQuest: currentQuest,
                  isAnswered: isAnswered,
                  hintUsed: hintUsed,
                  lives: lvs,
                  soundService: di.sl<SoundService>(),
                  onInfoTap: () {}, // GameBaseLayout handles briefing
                  onHint: () {
                    context.read<ReadingBloc>().add(const ReadingHintUsed());
                    onHint();
                  },
                ),
                if (passage != null && !isAnswered)
                  ReadingPassageArea(
                    passage: passage!,
                    primaryColor: theme.primaryColor,
                    isDark: isDark,
                  ),
              ],
            );
          },
          feedbackBuilder: (context, s) {
            if (s is! ReadingLoaded) return const SizedBox.shrink();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final theme = LevelThemeHelper.getTheme(
              gameType.name,
              isDark: isDark,
              level: level,
            );
            final quest = s.currentQuest;
            String? explanation = quest.explanation;
            final resolvedIsFinalFailure = s.isFinalFailure;
            if (explanation == null &&
                isCorrect == false &&
                resolvedIsFinalFailure) {
              if (quest.correctAnswerIndex != null &&
                  quest.options != null &&
                  quest.options!.isNotEmpty) {
                explanation = quest.options![quest.correctAnswerIndex!];
              }
            }

            final ruleContent = quest.passage ?? explanation;
            final finalExplanation = (ruleContent == explanation)
                ? null
                : explanation;

            return GameFeedbackCard(
              isCorrect: isCorrect,
              isFinalFailure: resolvedIsFinalFailure,
              livesRemaining: s.livesRemaining,
              onContinue: onContinue,
              isDark: isDark,
              primaryColor: theme.primaryColor,
              explanation: finalExplanation,
              ruleTitle: context.tr(
                'common.reading_context',
                fallback: 'READING CONTEXT',
              ),
              ruleContent: ruleContent,
              isTwoStageGame: hasStage2,
            );
          },
        );
      },
    );
  }
}
