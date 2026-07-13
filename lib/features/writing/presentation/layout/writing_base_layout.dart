import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/core/presentation/widgets/writing/ink_streak.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_feedback_card.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/core/utils/locale_service.dart';

class WritingBaseLayout extends StatefulWidget {
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
  State<WritingBaseLayout> createState() => _WritingBaseLayoutState();
}

class _WritingBaseLayoutState extends State<WritingBaseLayout> {
  final _ttsService = di.sl<TtsService>();
  final _soundService = di.sl<SoundService>();
  bool _hasSpokenNudge = false;
  int _lastIndex = -1;
  int _lastLives = 3;
  late bool _showBriefing;

  @override
  void initState() {
    super.initState();
    _showBriefing = widget.level == 1 || widget.level == 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocListener<WritingBloc, WritingState>(
      listenWhen: (previous, current) {
        if (current is WritingLoaded) {
          if (previous is! WritingLoaded) return true;
          return previous.currentIndex != current.currentIndex ||
              previous.livesRemaining != current.livesRemaining;
        }
        return false;
      },
      listener: (context, state) {
        if (state is WritingLoaded) {
          // Detect the exact transition from 2 lives to 1 life
          final justDroppedToLastLife =
              _lastLives == 2 && state.livesRemaining == 1;

          if (state.currentIndex != _lastIndex) {
            _lastIndex = state.currentIndex;
          }

          if (justDroppedToLastLife && !_hasSpokenNudge) {
            _hasSpokenNudge = true; // Permanent for this session
            final nudgeMessage = context.tr('games.kids_nudge', fallback: 'Let\'s go!');
            // Delay to allow the "Wrong" sound effect to finish
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) {
                _ttsService.speak(nudgeMessage);
                di.sl<HapticService>().warning();
              }
            });
          }
          _lastLives = state.livesRemaining;
        }
      },
      child: BlocBuilder<WritingBloc, WritingState>(
        builder: (context, state) {
          final isComplete = state is WritingGameComplete;
          if (state is WritingError) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: theme.backgroundColors[1],
              body: GameErrorWidget(
                message: state.message,
                onRetry: () => context.read<WritingBloc>().add(
                  FetchWritingQuests(
                    gameType: widget.gameType,
                    level: widget.level,
                  ),
                ),
                onBack: () => Navigator.pop(context),
                primaryColor: theme.primaryColor,
              ),
            );
          }
          return PopScope(
            canPop: isComplete,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              GameDialogHelper.showExitConfirmation(
                this.context,
                onQuit: () => Navigator.of(this.context).pop(),
              );
            },
            child: Builder(
              builder: (context) {
                final progress = (state is WritingLoaded)
                    ? (state.currentIndex + 1) / state.quests.length
                    : (state is WritingGameComplete ? 1.0 : 0.0);
                final lives = (state is WritingLoaded)
                    ? state.livesRemaining
                    : 3;
                final currentQuest = (state is WritingLoaded)
                    ? state.currentQuest
                    : null;

                return Scaffold(
                  backgroundColor: theme.backgroundColors[1],
                  body: Stack(
                    children: [
                      Container(
                        color: theme.backgroundColors[1],
                      ), // Prevent white splash
                      MeshGradientBackground(colors: theme.backgroundColors),
                      InkStreak(
                        color: theme.primaryColor.withValues(alpha: 0.15),
                      ),
                      if (state is WritingLoading)
                        GameShimmerLoading(primaryColor: theme.primaryColor)
                      else ...[
                        SafeArea(
                          child: Column(
                            children: [
                              SizedBox(height: 10.h),
                              _buildHeader(
                                context,
                                state,
                                widget.level,
                                progress,
                                lives,
                                theme,
                                isDark,
                                currentQuest,
                              ),

                              Expanded(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      opacity: widget.isAnswered ? 0.6 : 1.0,
                                      child: AbsorbPointer(
                                        absorbing: widget.isAnswered,
                                        child: widget.useScrolling
                                            ? LayoutBuilder(
                                                builder: (context, constraints) {
                                                  return SingleChildScrollView(
                                                    physics:
                                                        const BouncingScrollPhysics(),
                                                    child: ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                            minHeight:
                                                                constraints
                                                                    .maxHeight,
                                                          ),
                                                      child: Padding(
                                                        padding: EdgeInsets.only(
                                                          left:
                                                              widget
                                                                  .disablePadding
                                                              ? 0
                                                              : 24.w,
                                                          right:
                                                              widget
                                                                  .disablePadding
                                                              ? 0
                                                              : 24.w,
                                                          top:
                                                              widget
                                                                  .disablePadding
                                                              ? 0
                                                              : 20.h,
                                                          bottom:
                                                              (widget.disablePadding
                                                                  ? 0
                                                                  : (widget.isAnswered
                                                                        ? 200.h
                                                                        : 40.h)) +
                                                              MediaQuery.of(
                                                                    context,
                                                                  )
                                                                  .viewInsets
                                                                  .bottom,
                                                        ),
                                                        child: widget.child,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Padding(
                                                padding: EdgeInsets.only(
                                                  left: widget.disablePadding
                                                      ? 0
                                                      : 24.w,
                                                  right: widget.disablePadding
                                                      ? 0
                                                      : 24.w,
                                                  top: widget.disablePadding
                                                      ? 0
                                                      : 20.h,
                                                  bottom:
                                                      (widget.disablePadding
                                                          ? 0
                                                          : (widget.isAnswered
                                                                ? 200.h
                                                                : 40.h)) +
                                                      MediaQuery.of(
                                                        context,
                                                      ).viewInsets.bottom,
                                                ),
                                                child: widget.child,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -20.h,
                                      right: 20.w,
                                      child: _buildPeekingMascot(state, lives),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (widget.isAnswered &&
                          state is! WritingGameOver &&
                          state is! WritingGameComplete)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: WritingFeedbackCard(
                            state: state,
                            isCorrect: widget.isCorrect,
                            onContinue: widget.onContinue,
                            isDark: isDark,
                            theme: theme,
                          ),
                        ),
                      if (widget.showConfetti) const GameConfetti(),

                      if (_showBriefing)
                        Builder(
                          builder: (context) {
                            final briefing = GameInstructionService.getBriefing(
                              context,
                              widget.gameType,
                              "Writing",
                              level: widget.level,
                            );
                            return QuestBriefingOverlay(
                              title: briefing.title,
                              objective: briefing.objective,
                              rules: briefing.rules,
                              actionText: briefing.actionText,
                              tip: briefing.tip,
                              icon: briefing.icon,
                              primaryColor: theme.primaryColor,
                              onStart: () =>
                                  setState(() => _showBriefing = false),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
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
    final hintShouldGlow = lives < 3 && !widget.isAnswered;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: GameProgressHeader(
              level: level,
              progress: progress,
              lives: lives,
              streak: (state is WritingLoaded) ? state.currentIndex : 0,
              theme: theme,
              isDark: isDark,
              onBack: () => GameDialogHelper.showExitConfirmation(
                this.context,
                onQuit: () => Navigator.pop(this.context),
              ),
            ),
          ),
          if (quest != null && !widget.isAnswered) ...[
            // MANUAL BRIEFING TRIGGER (Help Icon)
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: ScaleButton(
                onTap: () => setState(() => _showBriefing = true),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.2),
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
                    used: (state is WritingLoaded) ? state.hintUsed : false,
                    primaryColor: theme.primaryColor,
                    hintText: quest.hint,
                    soundService: _soundService,
                    onTap: () {
                      context.read<WritingBloc>().add(WritingHintUsed());
                      widget.onHint();
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
                  if (quest.hint != null) ...[
                    SizedBox(width: 8.w),
                    TranslateButtonWidget(
                      originalText: quest.hint,
                      onTranslationComplete: (translated) {
                        CustomSnackBar.show(
                          context: context,
                          message: translated,
                          type: CustomSnackBarType.info,
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

  Widget _buildPeekingMascot(WritingState state, int lives) {
    final mascotState = _getMascotState(state, lives);
    final authState = context.read<AuthBloc>().state;
    final mascotId = authState.user?.vowlMascot ?? 'vowl_prime';
    final mascotName = mascotId
        .split('_')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');

    String message = "Write with flair! 🖋️";
    if (widget.isCorrect == true) {
      message = "Literary Genius! ✨";
    } else if (lives < 3 && !widget.isAnswered) {
      message = "Find your voice! 💡";
    } else if (widget.isCorrect == false) {
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
      if (widget.isCorrect == true) return VowlMascotState.happy;
      if (lives < 3 && !widget.isAnswered) return VowlMascotState.worried;
      if (widget.isCorrect == false) return VowlMascotState.thinking;
    }
    return VowlMascotState.neutral;
  }
}
