import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_content_body.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_header.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_peeking_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/layout/game_briefing_scope.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

// ---------------------------------------------------------------------------
// AccentBaseLayout
// ---------------------------------------------------------------------------

/// Scaffold shell providing common background styling, mascot peeking, feedback drawers, and progress bars for accent games.
class AccentBaseLayout extends StatelessWidget {
  /// The active accent subtype.
  final GameSubtype gameType;

  /// The active level index.
  final int level;

  /// The core question-specific widget tree.
  final Widget child;

  /// Whether the user has submitted their trial answer.
  final bool isAnswered;

  /// Evaluation outcome of the submitted trial (`null` if unanswered).
  final bool? isCorrect;

  /// Callback executed when the user taps continue on the feedback drawer.
  final VoidCallback onContinue;

  /// Callback executed when the hint button is pressed.
  final VoidCallback onHint;

  /// Whether confetti particle animations should be active.
  final bool showConfetti;

  /// Whether the content body should be wrapped in a scroll view.
  final bool useScrolling;

  /// Whether layout padding around the content body should be suppressed.
  final bool disablePadding;

  /// Creates an [AccentBaseLayout] widget.
  const AccentBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.isCorrect,
    required this.onContinue,
    required this.onHint,

    this.showConfetti = false,
    this.useScrolling = false,
    this.disablePadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: level);

    // Subscribes only to vowlMascot changes — not every AuthState emission.
    final mascotId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.vowlMascot ?? 'vowl_prime',
    );

    final wrappedChild = AccentContentBody(
      useScrolling: useScrolling,
      disablePadding: disablePadding,
      isAnswered: isAnswered,
      primaryColor: theme.primaryColor,
      isDark: isDark,
      child: child,
    );

    final config = GameScaffoldConfig(
      gameType: gameType,
      level: level,
      child: wrappedChild,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      isFinalFailure: false, // Handled internally
      onContinue: onContinue,
      onHint: onHint,
      showConfetti: showConfetti,
      useScrolling: false, // Handled internally by AccentContentBody
      disablePadding: true, // Handled internally by AccentContentBody
    );

    return GameBaseLayout<AccentBloc, AccentState>(
      config: config,
      stateMapper: (s) => s,
      onRetry: () => context.read<AccentBloc>().add(
        FetchAccentQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () => context.read<AccentBloc>().add(const RestoreLife()),

      headerBuilder: (context, state, progress, lives) {
        return AccentHeader(
          level: level,
          progress: progress,
          lives: lives,
          streak: state is AccentLoaded ? state.currentIndex : 0,
          isDark: isDark,
          quest: state is AccentLoaded ? state.currentQuestOrNull : null,
          isAnswered: isAnswered,
          hintUsed: state is AccentLoaded ? state.hintUsed : false,
          soundService: di.sl<SoundService>(),
          onBack: () => GameDialogHelper.showExitConfirmation(
            context,
            onQuit: () => Navigator.pop(context),
          ),
          onShowBriefing: () => GameBriefingScope.show(context),
          onHintTap: () {
            context.read<AccentBloc>().add(const AccentHintUsed());
            onHint();
          },
        );
      },
      mascotBuilder: (context, state, lives) {
        return AccentPeekingMascot(
          state: state,
          lives: lives,
          mascotId: mascotId,
          isCorrect: isCorrect,
        );
      },
      feedbackBuilder: (context, state) {
        if (state is! AccentLoaded) return const SizedBox.shrink();
        final success = isCorrect ?? false;
        final explanationText =
            state.currentQuest.explanation ??
            (success
                ? "Excellent listening! You correctly identified the precise sound."
                : "Keep practicing! Pay close attention to the subtle differences in these sounds.");

        final rules = <PedagogicalRuleItem>[
          if (state.currentQuest.phoneticRule != null &&
              state.currentQuest.phoneticRule!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.psychology_rounded,
              title: context.tr('games.phonetic_rule', fallback: 'Phonetic Rule'),
              rule: state.currentQuest.phoneticRule!,
            ),
          if (state.currentQuest.mouthPosition != null &&
              state.currentQuest.mouthPosition!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.face_retouching_natural_rounded,
              title: context.tr('games.mouth_position', fallback: 'Mouth Position'),
              rule: state.currentQuest.mouthPosition!,
            ),
          if (state.currentQuest.dialectNote != null &&
              state.currentQuest.dialectNote!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.public,
              title: context.tr('games.dialect_note', fallback: 'Dialect Note'),
              rule: state.currentQuest.dialectNote!,
            ),
          if (state.currentQuest.pitchRule != null &&
              state.currentQuest.pitchRule!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.show_chart,
              title: context.tr('games.pitch_rule', fallback: 'Pitch Rule'),
              rule: state.currentQuest.pitchRule!,
            ),
          if (state.currentQuest.vowelTensionRule != null &&
              state.currentQuest.vowelTensionRule!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.waves_rounded,
              title: context.tr('games.vowel_tension', fallback: 'Vowel Tension'),
              rule: state.currentQuest.vowelTensionRule!,
            ),
          if (state.currentQuest.modulationPattern != null &&
              state.currentQuest.modulationPattern!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.graphic_eq_rounded,
              title: context.tr('games.modulation_pattern', fallback: 'Modulation Pattern'),
              rule: state.currentQuest.modulationPattern!,
            ),
          if (state.currentQuest.emphasisRule != null &&
              state.currentQuest.emphasisRule!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.priority_high_rounded,
              title: context.tr('games.emphasis_rule', fallback: 'Emphasis Rule'),
              rule: state.currentQuest.emphasisRule!,
            ),
          if (state.currentQuest.flowRule != null &&
              state.currentQuest.flowRule!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.water_drop_rounded,
              title: context.tr('games.flow_rule', fallback: 'Flow Rule'),
              rule: state.currentQuest.flowRule!,
            ),
          if (state.currentQuest.pacingRule != null &&
              state.currentQuest.pacingRule!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.speed_rounded,
              title: context.tr('games.pacing_rule', fallback: 'Pacing Rule'),
              rule: state.currentQuest.pacingRule!,
            ),
          if (state.currentQuest.stressRule != null &&
              state.currentQuest.stressRule!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.compress_rounded,
              title: context.tr('games.stress_rule', fallback: 'Stress Rule'),
              rule: state.currentQuest.stressRule!,
            ),
          if (state.currentQuest.meaningShift != null &&
              state.currentQuest.meaningShift!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.compare_arrows_rounded,
              title: context.tr('games.meaning_shift', fallback: 'Meaning Shift'),
              rule: state.currentQuest.meaningShift!,
            ),
        ];

        final String? resolvedCorrectAnswer =
            (!success && state.isFinalFailure)
                ? (state.currentQuest.correctAnswer ??
                    state.currentQuest.word ??
                    (state.currentQuest.options != null &&
                            state.currentQuest.correctAnswerIndex != null &&
                            state.currentQuest.correctAnswerIndex! >= 0 &&
                            state.currentQuest.correctAnswerIndex! <
                                state.currentQuest.options!.length
                        ? state.currentQuest.options![
                            state.currentQuest.correctAnswerIndex!]
                        : null))
                : null;

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: state.isFinalFailure,
          livesRemaining: state.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor,
          explanation: explanationText,
          correctAnswer: resolvedCorrectAnswer,
          sampleAnswer: state.currentQuest.sampleAnswer,
          pedagogicalRules: rules.isNotEmpty ? rules : null,
        );
      },
    );
  }
}
