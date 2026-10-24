import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_game_header.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_peeking_mascot.dart';

import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/layout/game_briefing_scope.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

// =============================================================================
// SpeakingBaseLayout
// =============================================================================

/// Common screen layout scaffold providing standard headers, feedback, and dialogs for speaking challenges.
class SpeakingBaseLayout extends StatelessWidget {
  /// Speaking subgame variant.
  final GameSubtype gameType;

  /// Target progression difficulty level.
  final int level;

  /// Main question or interaction body widget.
  final Widget child;

  /// Whether the user has submitted their verbal attempt.
  final bool isAnswered;

  /// Whether the submitted attempt was evaluated as correct.
  final bool? isCorrect;

  /// Whether all retry lives have been exhausted.
  final bool isFinalFailure;

  /// Callback executed when tapping continue to advance.
  final VoidCallback onContinue;

  /// Callback executed when tapping the hint button.
  final VoidCallback onHint;

  /// Whether victory confetti should be displayed.
  final bool showConfetti;

  /// Whether internal body content should enable scrolling.
  final bool useScrolling;

  /// Whether horizontal outer padding should be omitted.
  final bool disablePadding;

  /// Whether the hint action button is rendered in the header.
  final bool showHintButton;

  /// Optional service overrides — inject mocks in widget tests to avoid
  /// requiring a live DI container. Production code leaves these null and
  /// the State falls back to [di.sl].

  /// Optional text-to-speech engine override.
  final TtsService? ttsService;

  /// Optional sound effects service override.
  final SoundService? soundService;

  /// Optional haptic feedback service override.
  final HapticService? hapticService;

  /// Creates a [SpeakingBaseLayout] scaffold.
  const SpeakingBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    required this.onContinue,
    required this.onHint,
    this.showHintButton = true,

    this.isCorrect,
    this.isFinalFailure = false,
    this.showConfetti = false,
    this.useScrolling = false,
    this.disablePadding = false,
    this.ttsService,
    this.soundService,
    this.hapticService,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mascotId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.vowlMascot ?? 'vowl_prime',
    );
    final mascotName = mascotId
        .split('_')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');

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

    return GameBaseLayout<SpeakingBloc, SpeakingState>(
      config: config,
      stateMapper: (s) => s,
      onRetry: () => context.read<SpeakingBloc>().add(
        FetchSpeakingQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () =>
          context.read<SpeakingBloc>().add(const RestoreLife()),

      headerBuilder: (context, state, progress, lives) {
        final currentQuest = state is SpeakingLoaded
            ? state.currentQuestOrNull
            : null;
        final hintUsed = state is SpeakingLoaded ? state.hintUsed : false;
        final streak = state is SpeakingLoaded ? state.currentIndex : 0;

        return SpeakingGameHeader(
          level: level,
          progress: progress,
          lives: lives,
          streak: streak,
          quest: currentQuest,
          isAnswered: isAnswered,
          hintUsed: hintUsed,
          soundService: soundService ?? di.sl<SoundService>(),
          isDark: isDark,
          showHintButton: showHintButton,
          onBack: () => GameDialogHelper.showExitConfirmation(
            context,
            onQuit: () => Navigator.of(context).pop(),
          ),
          onHintTap: onHint,
          onInfoTap: () => GameBriefingScope.show(context),
        );
      },
      mascotBuilder: (context, state, lives) {
        return SpeakingPeekingMascot(
          state: state,
          lives: lives,
          isCorrect: isCorrect,
          isAnswered: isAnswered,
          mascotId: mascotId,
          mascotName: mascotName,
        );
      },
      feedbackBuilder: (context, state) {
        if (state is! SpeakingLoaded) return const SizedBox.shrink();
        final theme = LevelThemeHelper.getTheme(
          'speaking',
          level: level,
          isDark: isDark,
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

        final ruleContent = quest.meaning ?? explanation;
        final finalExplanation = (ruleContent == explanation)
            ? null
            : explanation;

        final finalSampleAnswer =
            (quest.sampleAnswer != null &&
                quest.sampleAnswer!.startsWith('Here is a sample response'))
            ? quest.correctAnswer
            : quest.sampleAnswer;

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: resolvedIsFinalFailure,
          livesRemaining: state.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor,
          explanation: finalExplanation,
          ruleTitle: context.tr(
            'common.speaking_tip',
            fallback: 'SPEAKING TIP',
          ),
          ruleContent: ruleContent,
          sampleAnswer: finalSampleAnswer,
        );
      },
    );
  }
}
