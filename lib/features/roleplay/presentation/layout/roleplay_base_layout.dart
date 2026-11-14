import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/presentation/widgets/games/headers/vowl_universal_game_header.dart';
import 'package:vowl/core/presentation/widgets/games/dialogs/vowl_pause_bottom_sheet.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_peeking_mascot.dart';
import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/layout/game_briefing_scope.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

/// Standard base layout scaffold for all roleplay minigames.
///
/// Wraps gameplay screens with a unified header, lives/progress indicator,
/// peeking mascot, hints, and feedback cards.
class RoleplayBaseLayout extends StatelessWidget {
  /// Game subtype for this session.
  final GameSubtype gameType;

  /// Current level index.
  final int level;

  /// Minigame content widget.
  final Widget child;

  /// Whether the player has submitted an answer for the current question.
  final bool isAnswered;

  /// Whether the submitted answer was correct, or `null` if unanswered.
  final bool? isCorrect;

  /// Whether the current question reached final failure after exhausting attempts.
  final bool isFinalFailure;

  /// Callback invoked when continuing to the next question.
  final VoidCallback onContinue;

  /// Callback invoked when a hint is requested.
  final VoidCallback onHint;

  /// Whether confetti animation should be displayed.
  final bool showConfetti;

  /// Optional scroll controller for the content area.
  final ScrollController? scrollController;

  /// Whether the layout should wrap content in a scrollable view.
  final bool useScrolling;

  /// Whether default padding around the child should be disabled.
  final bool disablePadding;

  /// Identifier for the mascot asset.
  final String mascotId;

  /// Whether the content should span full screen width without constraint.
  final bool fullScreenContent;

  /// Creates a [RoleplayBaseLayout] widget.
  const RoleplayBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.mascotId = kRoleplayDefaultMascotId,
    this.isCorrect,
    this.isFinalFailure = false,
    required this.onContinue,
    required this.onHint,

    this.showConfetti = false,
    this.scrollController,
    this.useScrolling = false,
    this.disablePadding = false,
    this.fullScreenContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final wrappedChild = fullScreenContent
        ? child
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: kRoleplayMaxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [child],
              ),
            ),
          );

    final config = GameScaffoldConfig(
      gameType: gameType,
      level: level,
      child: wrappedChild,
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

    return GameBaseLayout<RoleplayBloc, RoleplayState>(
      config: config,
      stateMapper: (s) => s,
      onRetry: () => context.read<RoleplayBloc>().add(
        FetchRoleplayQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () =>
          context.read<RoleplayBloc>().add(const RestoreLife()),

      headerBuilder: (context, state, progress, lives) {
        final currentQuest = state is RoleplayLoaded ? state.currentQuestOrNull : null;

        return VowlUniversalGameHeader(
          level: level,
          category: 'roleplay',
          progress: progress,
          lives: lives,
          hintText: currentQuest?.hint,
          isHintUsedOnCurrentQuest: state is RoleplayLoaded ? state.hintUsed : false,
          isHintEnabled: currentQuest != null && !isAnswered,
          onPause: () {
            VowlPauseBottomSheet.show(
              context,
              category: 'roleplay',
              onResume: () {},
              onRestart: () {
                context.read<RoleplayBloc>().add(
                  FetchRoleplayQuests(gameType: gameType, level: level),
                );
              },
              onQuit: () => Navigator.of(context).pop(),
            );
          },
          onBriefing: () => GameBriefingScope.show(context),
          onHint: () {
            context.read<RoleplayBloc>().add(const RoleplayHintUsed());
            onHint();
          },
        );
      },
      mascotBuilder: (context, state, lives) {
        return RoleplayPeekingMascot(
          state: state,
          lives: lives,
          isCorrect: isCorrect,
          isAnswered: isAnswered,
          mascotId: mascotId,
        );
      },
      feedbackBuilder: (context, state) {
        if (state is! RoleplayLoaded) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = LevelThemeHelper.of(context, 'roleplay', level: level);

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

        final ruleContent =
            quest.situation ?? quest.scene ?? quest.socialContext;
        final finalExplanation = quest.explanation;

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: resolvedIsFinalFailure,
          livesRemaining: state.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor,
          explanation: finalExplanation,
          ruleTitle: 'SCENARIO CONTEXT',
          ruleContent: ruleContent,
          sampleAnswer: quest.sampleAnswer ?? quest.correctAnswer,
        );
      },
    );
  }
}
