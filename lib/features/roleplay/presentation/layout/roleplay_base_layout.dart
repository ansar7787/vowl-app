import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/accent/harmonic_waves.dart';
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
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

class RoleplayBaseLayout extends StatelessWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final bool isFinalFailure;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final VoidCallback? onTutorPass;
  final bool showConfetti;
  final String title;
  final String subtitle;
  final ScrollController? scrollController;
  final bool useScrolling;
  final bool disablePadding;
  final String mascotId;

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
    this.onTutorPass,
    this.showConfetti = false,
    this.title = 'SOCIAL SCENARIO',
    this.subtitle = 'Master the Scene',
    this.scrollController,
    this.useScrolling = false,
    this.disablePadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final wrappedChild = Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final theme = LevelThemeHelper.getTheme('roleplay', level: level);
      
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kRoleplayMaxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: theme.primaryColor,
                ),
              ).animate().fadeIn(),
              SizedBox(height: 8.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              SizedBox(height: 32.h),
              child,
            ],
          ),
        ),
      );
    });

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
      onRestoreLife: () => context.read<RoleplayBloc>().add(const RestoreLife()),
      backgroundOverlay: Builder(
        builder: (context) {
          final theme = LevelThemeHelper.getTheme('roleplay', level: level);
          return RepaintBoundary(
            child: HarmonicWaves(
              color: (theme.primaryColor).withValues(alpha: 0.3),
              height: 150.h,
            ),
          );
        },
      ),
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
        if (explanation == null && isCorrect == false && isFinalFailure) {
           if (quest.correctAnswerIndex != null && quest.options != null && quest.options!.isNotEmpty) {
               explanation = quest.options![quest.correctAnswerIndex!];
           }
        }

        final ruleContent = quest.situation ?? quest.scene ?? explanation;
        final finalExplanation = (ruleContent == explanation) ? null : explanation;

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          livesRemaining: state.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor,
          explanation: finalExplanation,
          ruleTitle: 'SCENARIO CONTEXT',
          ruleContent: ruleContent,
          sampleAnswer: quest.sampleAnswer,
          onTutorPass: onTutorPass,
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
