import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/core/presentation/widgets/grammar/logic_circuit.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_game_header.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_peeking_mascot.dart';

import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

class GrammarBaseLayout extends StatelessWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final bool isFinalFailure;
  final bool useScrolling;
  final bool disablePadding;

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

    return GameBaseLayout<GrammarBloc, GrammarState>(
      config: config,
      stateMapper: (state) => state,
      backgroundOverlay: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final theme = LevelThemeHelper.getTheme('grammar', level: level, isDark: isDark);
          return Positioned.fill(
            child: LogicCircuit(
              color: (theme.primaryColor).withValues(alpha: 0.2),
            ),
          );
        }
      ),
      onRetry: () => context.read<GrammarBloc>().add(
        FetchGrammarQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () => context.read<GrammarBloc>().add(const RestoreLife()),
      headerBuilder: (context, state, progress, lives) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = LevelThemeHelper.getTheme('grammar', isDark: isDark, level: level);
        final currentQuest = state is GrammarLoaded ? state.currentQuestOrNull : null;
        return GrammarGameHeader(
          state: state,
          level: level,
          progress: progress,
          lives: lives,
          theme: theme,
          quest: currentQuest,
          isAnswered: isAnswered,
          isFinalFailure: isFinalFailure,
          soundService: di.sl<SoundService>(),
          onShowBriefing: () {}, // GameBaseLayout handles briefing internally now
          onHint: onHint,
        );
      },
      mascotBuilder: (context, state, lives) {
        final mascotId = context.read<AuthBloc>().state.user?.vowlMascot ?? 'vowl_prime';
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = LevelThemeHelper.getTheme('grammar', level: level, isDark: isDark);
        
        final quest = state.currentQuest;
        String? explanation = quest.explanation;
        if (explanation == null && isCorrect == false && isFinalFailure) {
           explanation = (quest.options != null && quest.correctAnswerIndex != null
               ? quest.options![quest.correctAnswerIndex!]
               : null);
        }

        final ruleContent = quest.grammarRule ?? explanation;
        final finalExplanation = (ruleContent == explanation) ? null : explanation;

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
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
