import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/core/presentation/widgets/writing/ink_streak.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

class WritingBaseLayout extends StatelessWidget {
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
    final mascotId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.vowlMascot ?? 'vowl_prime',
    );
    final mascotName = mascotId
        .split('_')
        .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
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

    return GameBaseLayout<WritingBloc, WritingState>(
      config: config,
      stateMapper: (s) => s,
      onRetry: () => context.read<WritingBloc>().add(
        FetchWritingQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () => context.read<WritingBloc>().add(const RestoreLife()),
      backgroundOverlay: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final theme = LevelThemeHelper.getTheme('writing', level: level, isDark: isDark);
          return Positioned.fill(
            child: InkStreak(
              color: theme.primaryColor.withValues(alpha: 0.15),
            ),
          );
        }
      ),
      headerBuilder: (context, state, progress, lives) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = LevelThemeHelper.getTheme('writing', isDark: isDark, level: level);
        final currentQuest = state is WritingLoaded ? state.currentQuestOrNull : null;
        
        return _buildHeader(
          context,
          state,
          level,
          progress,
          lives,
          theme,
          isDark,
          currentQuest,
        );
      },
      mascotBuilder: (context, state, lives) {
        return _buildPeekingMascot(context, state, lives, mascotId, mascotName);
      },
      feedbackBuilder: (context, state) {
        if (state is! WritingLoaded) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = LevelThemeHelper.getTheme('writing', isDark: isDark, level: level);
        final quest = state.currentQuest;

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          livesRemaining: state.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor as Color,
          explanation: quest.explanation,
          sampleAnswer: quest.sampleAnswer,
          requiredPoints: quest.requiredPoints,
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WritingState state,
    int level,
    double progress,
    int lives,
    dynamic theme,
    bool isDark,
    dynamic quest,
  ) {
    final hintShouldGlow = lives < 3 && !isAnswered;
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
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuestHintButton(
                        used: (state is WritingLoaded) ? state.hintUsed : false,
                        primaryColor: theme.primaryColor,
                        hintText: quest.hint,
                        soundService: di.sl<SoundService>(),
                        onTap: () {
                          context.read<WritingBloc>().add(const WritingHintUsed());
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
                  if (quest.hint != null &&
                      ((state is WritingLoaded) ? state.hintUsed : false)) ...[
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

  Widget _buildPeekingMascot(
    BuildContext context,
    WritingState state, 
    int lives,
    String mascotId,
    String mascotName,
  ) {
    final mascotState = _getMascotState(state, lives);
    String message = "Write with flair! 🖋️";
    if (isCorrect == true) {
      message = "Literary Genius! ✨";
    } else if (lives < 3 && !isAnswered) {
      message = "Find your voice! 💡";
    } else if (isCorrect == false) {
      message = "Refine the prose! 📜";
    } else if (state is WritingGameComplete) {
      message = "Author Extraordinaire! 🏆";
    } else {
      message = "$mascotName is waiting! 🦉";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 2.seconds,
            ),
        SizedBox(height: 0.h),
        VowlMascot(state: mascotState, size: 45.r, mascotId: mascotId)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: 5,
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  VowlMascotState _getMascotState(WritingState state, int lives) {
    if (state is WritingGameComplete) return VowlMascotState.happy;
    if (state is WritingGameOver) return VowlMascotState.worried;
    if (state is WritingLoaded) {
      if (isCorrect == true) return VowlMascotState.happy;
      if (lives < 3 && !isAnswered) return VowlMascotState.worried;
      if (isCorrect == false) return VowlMascotState.thinking;
    }
    return VowlMascotState.neutral;
  }
}
