import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';

import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/elite_mastery/domain/entities/elite_mastery_quest.dart';
import 'package:vowl/core/presentation/widgets/games/headers/vowl_universal_game_header.dart';
import 'package:vowl/core/presentation/widgets/games/dialogs/vowl_pause_bottom_sheet.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_peeking_mascot.dart';

import '../bloc/elite_mastery_bloc.dart';

import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';
import 'package:vowl/core/theme/app_spacing.dart';

/// Base scaffold and presentation wrapper for all Elite Mastery game screens.
class EliteBaseLayout extends StatelessWidget {
  /// Subtype variant of the active challenge.
  final GameSubtype gameType;

  /// Current curriculum difficulty level.
  final int level;

  /// Main question or interaction body widget.
  final Widget child;

  /// Whether the user has submitted their response.
  final bool isAnswered;

  /// Whether the submitted response was evaluated as correct.
  final bool? isCorrect;

  /// Callback executed when tapping the action button to advance.
  final VoidCallback onContinue;

  /// Callback executed when the hint action is triggered.
  final VoidCallback onHint;

  /// Whether victory confetti should be showered upon success.
  final bool showConfetti;

  /// Whether all retry chances have been exhausted.
  final bool isFinalFailure;

  /// Optional visual styling overrides for headers and backgrounds.
  final VisualConfig? visualConfig;

  /// Current snapshot of [EliteMasteryState].
  final EliteMasteryState state;

  /// Whether the interior layout should enable scrolling.
  final bool useScrolling;

  /// Scroll controller attached to the scrollable viewport.
  final ScrollController? scrollController;

  /// Whether standard horizontal padding should be omitted.
  final bool disablePadding;

  /// Whether content should fill the entire screen viewport.
  final bool fullScreenContent;

  /// Creates an [EliteBaseLayout] scaffold.
  const EliteBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    required this.state,
    this.isCorrect,
    this.isFinalFailure = false,
    required this.onContinue,
    required this.onHint,
    this.showConfetti = false,
    this.visualConfig,

    this.useScrolling = true,
    this.scrollController,
    this.disablePadding = false,
    this.fullScreenContent = false,
    this.onPause,
    this.onResume,
  });

  /// Optional callback invoked when pausing the game.
  final VoidCallback? onPause;

  /// Optional callback invoked when resuming the game.
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.watch<ThemeCubit>();
    final isMidnight =
        (Theme.of(context).brightness == Brightness.dark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black);
    final theme = LevelThemeHelper.getTheme(
      gameType.name,
      level: level,
      isDark: isDark,
      isMidnight: isMidnight,
    );

    final wrappedChild = fullScreenContent
        ? child
        : Builder(
            builder: (context) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 60.h),
                      // Titles removed to standardize global layout cleanliness
                      SizedBox(height: 20.h),
                      child,
                    ],
                  ),
                ),
              );
            },
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
      onBriefingShow: onPause,
      onBriefingDismiss: onResume,
    );

    return GameBaseLayout<EliteMasteryBloc, EliteMasteryState>(
      config: config,
      stateMapper: (s) => s,
      onRetry: () => context.read<EliteMasteryBloc>().add(
        FetchEliteMasteryQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () =>
          context.read<EliteMasteryBloc>().add(const RestoreEliteLife()),

      headerBuilder: (context, dynamicState, progress, lives) {
        final isLoaded = dynamicState is EliteMasteryLoaded;
        final currentQuest = isLoaded ? dynamicState.currentQuestOrNull : null;
        final hasHint = currentQuest?.hint != null && currentQuest!.hint!.trim().isNotEmpty;

        return VowlUniversalGameHeader(
          level: level,
          category: 'elitemastery',
          progress: progress,
          lives: lives,
          showHint: hasHint,
          hintText: currentQuest?.hint,
          isHintUsedOnCurrentQuest: isLoaded ? dynamicState.isHintUsed : false,
          isHintEnabled: !isAnswered,
          onPause: () {
            onPause?.call();
            VowlPauseBottomSheet.show(
              context,
              category: 'elitemastery',
              onResume: onResume,
              onRestart: () {
                context.read<EliteMasteryBloc>().add(
                  FetchEliteMasteryQuests(gameType: gameType, level: level),
                );
              },
            );
          },
          onHint: () {
            final bloc = context.read<EliteMasteryBloc>();
            final s = bloc.state;
            if (s is EliteMasteryLoaded) {
              if (!s.isHintUsed) {
                bloc.add(const MarkEliteHintUsed());
              }
              bloc.add(const ShowEliteHint());
            }
            onHint();
          },
        );
      },
      mascotBuilder: (context, dynamicState, lives) {
        return ElitePeekingMascot(
          state: dynamicState,
          lives: lives,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
        );
      },
      feedbackBuilder: (context, dynamicState) {
        if (dynamicState is! EliteMasteryLoaded) return const SizedBox.shrink();
        final quest = dynamicState.currentQuest;
        final bool isSuccess = isCorrect ?? false;
        final bool showPedagogy = isSuccess || dynamicState.isFinalFailure;

        final rules = <PedagogicalRuleItem>[
          if (showPedagogy &&
              quest.usageContext != null &&
              quest.usageContext!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.menu_book_rounded,
              title: context.tr(
                'games.semantic_usage_context_title',
                fallback: 'Usage Context',
              ),
              rule: quest.usageContext!,
            ),
          if (showPedagogy &&
              quest.spellingRule != null &&
              quest.spellingRule!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.spellcheck_rounded,
              title: context.tr(
                'games.semantic_spelling_pattern_title',
                fallback: 'Spelling Rule',
              ),
              rule: quest.spellingRule!,
            ),
          if (showPedagogy &&
              quest.sequenceLogic != null &&
              quest.sequenceLogic!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.alt_route_rounded,
              title: context.tr(
                'games.semantic_sequence_logic_title',
                fallback: 'Sequence Logic',
              ),
              rule: quest.sequenceLogic!,
            ),
          if (showPedagogy &&
              quest.shadowingFocus != null &&
              quest.shadowingFocus!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.record_voice_over_rounded,
              title: context.tr(
                'games.semantic_shadowing_focus_title',
                fallback: 'Shadowing Focus',
              ),
              rule: quest.shadowingFocus!,
            ),
          if (showPedagogy &&
              quest.targetAccent != null &&
              quest.targetAccent!.trim().isNotEmpty)
            PedagogicalRuleItem(
              icon: Icons.language_rounded,
              title: context.tr(
                'games.semantic_target_sound_title',
                fallback: 'Target Accent',
              ),
              rule: quest.targetAccent!,
            ),
        ];

        final String? resolvedCorrectAnswer =
            (!isSuccess && dynamicState.isFinalFailure)
            ? _resolveCorrectAnswer(quest)
            : null;

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: dynamicState.isFinalFailure,
          livesRemaining: dynamicState.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor,
          explanation: quest.explanation,
          correctAnswer: resolvedCorrectAnswer,
          pedagogicalRules: rules.isNotEmpty ? rules : null,
        );
      },
    );
  }

  static String? _resolveCorrectAnswer(EliteMasteryQuest quest) {
    if (quest.subtype == GameSubtype.storyBuilder &&
        quest.sentences != null &&
        quest.correctOrder != null) {
      final sentences = quest.sentences!;
      final ordered = quest.correctOrder!
          .where((i) => i >= 0 && i < sentences.length)
          .map((i) => sentences[i])
          .join('\n\n');
      return ordered.isNotEmpty ? ordered : null;
    }

    if (quest.subtype == GameSubtype.idiomMatch &&
        quest.options != null &&
        quest.correctAnswerIndex != null) {
      final idx = quest.correctAnswerIndex!;
      if (idx >= 0 && idx < quest.options!.length) {
        return quest.options![idx];
      }
    }

    if (quest.word != null) return quest.word;
    if (quest.correctAnswer != null) return quest.correctAnswer;
    if (quest.options != null && quest.correctAnswerIndex != null) {
      final idx = quest.correctAnswerIndex!;
      if (idx >= 0 && idx < quest.options!.length) {
        return quest.options![idx];
      }
    }
    return null;
  }
}
