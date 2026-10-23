import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_peeking_mascot.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/layout/game_briefing_scope.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = LevelThemeHelper.getTheme('roleplay', level: level);
        final quest = state is RoleplayLoaded ? state.currentQuestOrNull : null;
        final hintUsed = state is RoleplayLoaded ? state.hintUsed : false;

        return _buildHeader(
          context,
          state,
          theme,
          isDark,
          lives,
          progress,
          quest,
          hintUsed,
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
        final theme = LevelThemeHelper.getTheme('roleplay', level: level);

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

  Widget _buildHeader(
    BuildContext context,
    RoleplayState state,
    dynamic theme,
    bool isDark,
    int lives,
    double progress,
    dynamic quest,
    bool hintUsed,
  ) {
    final hintShouldGlow = lives < kRoleplayLowLifeThreshold && !isAnswered;
    final soundService = di.sl<SoundService>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: GameProgressHeader(
              level: level,
              progress: progress,
              lives: lives,
              theme: theme,
              isDark: isDark,
              onBack: () => GameDialogHelper.showExitConfirmation(
                context,
                onQuit: () => Navigator.pop(context),
              ),
            ),
          ),
          if (quest != null && !isAnswered) ...[
            SizedBox(width: 8.w),
            Semantics(
              label: context.tr(
                'roleplay.view_instructions',
                fallback: 'View level instructions',
              ),
              button: true,
              child: ScaleButton(
                onTap: () => GameBriefingScope.show(context),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: (theme.primaryColor as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          (theme.primaryColor as Color).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16.r,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuestHintButton(
                        used: hintUsed,
                        primaryColor: theme.primaryColor,
                        hintText: quest.hint,
                        soundService: soundService,
                        onTap: () {
                          context.read<RoleplayBloc>().add(
                            const RoleplayHintUsed(),
                          );
                          onHint();
                        },
                      )
                      .animate(
                        target: hintShouldGlow ? 1 : 0,
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .shimmer(
                        color: Colors.white.withValues(alpha: 0.5),
                        duration: 1.seconds,
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                      ),
                  if (quest.hint != null && hintUsed) ...[
                    SizedBox(width: 8.w),
                    TranslateButtonWidget(
                      originalText: quest.hint,
                      onTranslationComplete: (translated) {
                        CustomSnackBar.show(
                          context: context,
                          message: translated,
                          type: CustomSnackBarType.info,
                          duration: const Duration(seconds: 8),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
