import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/painters/visual_config_background.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import '../bloc/elite_mastery_bloc.dart';
import '../../../../features/vocabulary/flashcards/presentation/widgets/flashcard_header.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';

class EliteBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final String title;
  final String subtitle;
  final bool isFinalFailure;
  final VisualConfig? visualConfig;
  final EliteMasteryState state;

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
    required this.title,
    required this.subtitle,
    this.visualConfig,
  });

  @override
  State<EliteBaseLayout> createState() => _EliteBaseLayoutState();
}

class _EliteBaseLayoutState extends State<EliteBaseLayout> {
  final _ttsService = di.sl<TtsService>();
  bool _hasSpokenNudge = false;
  int _lastLives = 3;
  int _lastIndex = -1;
  late bool _showBriefing;

  @override
  void initState() {
    super.initState();
    _showBriefing = widget.level == 1 || widget.level == 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      level: widget.level,
      isDark: isDark,
      isMidnight: isMidnight,
    );

    final state = widget.state;
    final isComplete = state is EliteMasteryGameComplete;

    return BlocListener<EliteMasteryBloc, EliteMasteryState>(
      listenWhen: (previous, current) {
        if (current is EliteMasteryLoaded) {
          if (previous is! EliteMasteryLoaded) return true;
          return previous.currentIndex != current.currentIndex ||
              previous.livesRemaining != current.livesRemaining;
        }
        return false;
      },
      listener: (context, state) {
        if (state is EliteMasteryLoaded) {
          // Detect the exact transition from 2 lives to 1 life
          final justDroppedToLastLife = _lastLives == 2 && state.livesRemaining == 1;

          if (state.currentIndex != _lastIndex) {
            _lastIndex = state.currentIndex;
          }

          if (justDroppedToLastLife && !_hasSpokenNudge) {
            _hasSpokenNudge = true; // Permanent for this session
            // Delay to allow the "Wrong" sound effect to finish
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) {
                _ttsService.speak(
                  "Focus! Use a hint if you need help saving your last life.",
                );
                di.sl<HapticService>().warning();
              }
            });
          }
          _lastLives = state.livesRemaining;
        }
      },
      child: PopScope(
        canPop: isComplete,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          GameDialogHelper.showExitConfirmation(
            this.context,
            onQuit: () => Navigator.of(this.context).pop(),
          );
        },
        child: BlocBuilder<EliteMasteryBloc, EliteMasteryState>(
          builder: (context, state) {
            if (state is EliteMasteryError) {
              return Scaffold(
              resizeToAvoidBottomInset: false,
                backgroundColor: theme.backgroundColors[1],
                body: GameErrorWidget(
                  message: state.message,
                  onRetry: () => context.read<EliteMasteryBloc>().add(FetchEliteMasteryQuests(gameType: widget.gameType, level: widget.level)),
                  onBack: () => Navigator.pop(context),
                  primaryColor: theme.primaryColor,
                ),
              );
            }
            final progress = (state is EliteMasteryLoaded)
                ? (state.currentIndex + 1) / state.quests.length
                : (state is EliteMasteryGameComplete ? 1.0 : 0.0);
            final lives = (state is EliteMasteryLoaded) ? state.livesRemaining : 3;

            return Scaffold(
              backgroundColor: theme.backgroundColors[1],
              body: Stack(
                children: [
                  Container(
                    color: theme.backgroundColors[1],
                  ), // Prevent white splash
                  MeshGradientBackground(colors: theme.backgroundColors),
                  if (widget.visualConfig != null)
                    VisualConfigBackground(config: widget.visualConfig!)
                  else if (state is EliteMasteryLoaded &&
                      state.currentQuest.visualConfig != null)
                    VisualConfigBackground(
                      config: state.currentQuest.visualConfig!,
                    ),

                  if (state is EliteMasteryLoading)
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
                        ),

                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 400),
                                opacity: widget.isAnswered ? 0.6 : 1.0,
                                child: AbsorbPointer(
                                  absorbing: widget.isAnswered,
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.only(
                                      left: 24.w,
                                      right: 24.w,
                                      top: 20.h,
                                      bottom: (widget.isAnswered ? 200.h : 40.h) + MediaQuery.of(context).viewInsets.bottom,
                                    ),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: 500.h,
                                        ), // Encourages centered feel
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              widget.title,
                                              style: GoogleFonts.outfit(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 4,
                                                color: isDark ? Colors.white70 : const Color(0xFF1E293B).withValues(alpha: 0.7),
                                              ),
                                            ).animate().fadeIn(),
                                            SizedBox(height: 8.h),
                                            Text(
                                              widget.subtitle,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.outfit(
                                                fontSize: 22.sp,
                                                fontWeight: FontWeight.w900,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ).animate().fadeIn().slideY(begin: 0.1),
                                            SizedBox(height: 32.h),
                                            widget.child,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -10.h,
                                left: 20.w,
                                child: _buildPeekingMascot(
                                  state,
                                  lives,
                                  widget.isAnswered,
                                  widget.isCorrect,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (widget.isAnswered && state is! EliteMasteryGameOver && state is! EliteMasteryGameComplete)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildModernFeedbackCard(
                      context,
                      state,
                      theme,
                      isDark,
                    ),
                  ),

                if (widget.showConfetti) const GameConfetti(),

                if (_showBriefing)
                  Builder(
                    builder: (context) {
                      final briefing = GameInstructionService.getBriefing(
                        widget.gameType,
                        widget.title,
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
                        onStart: () => setState(() => _showBriefing = false),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    EliteMasteryState state,
    int level,
    double progress,
    int lives,
    dynamic theme,
    bool isDark,
  ) {
    final hintShouldGlow = lives < 3 && !widget.isAnswered;
    final quest = (state is EliteMasteryLoaded) ? state.currentQuest : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: FlashcardHeader(
              level: level,
              progress: progress,
              lives: lives,
              streak: (state is EliteMasteryLoaded) ? state.currentIndex : 0,
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
              child:
                  QuestHintButton(
                        used: (state is EliteMasteryLoaded)
                            ? state.isHintUsed
                            : false,
                        primaryColor: theme.primaryColor,
                        hintText: quest.hint,
                        soundService: di.sl<SoundService>(),
                        onTap: widget.onHint,
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeekingMascot(EliteMasteryState state, int lives, bool isAnswered, bool? isCorrect) {
    final mascotState = _getMascotState(state, lives, isAnswered, isCorrect);
    final authState = context.read<AuthBloc>().state;
    final mascotId = authState.user?.vowlMascot ?? 'vowl_prime';
    final mascotName = mascotId.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');

    String message = "Focus on the goal!";
    if (isCorrect == true) {
      message = "Legendary insight! ✨";
    } else if (lives < 3 && !isAnswered) {
      message = "A hint could help! 💡";
    } else if (isCorrect == false) {
      message = "Almost there! 🔍";
    } else if (state is EliteMasteryGameComplete) {
      message = "Mastery Achieved! 🏆";
    } else {
      message = "$mascotName is watching! 🦉";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
          child: Text(message, style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B))),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
        SizedBox(height: 0.h),
        VowlMascot(state: mascotState, size: 45.r, mascotId: mascotId).animate(onPlay: (c) => c.repeat(reverse: true))
         .moveY(begin: 0, end: 5, duration: 1500.ms, curve: Curves.easeInOut),
      ],
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildModernFeedbackCard(
    BuildContext context,
    EliteMasteryState state,
    dynamic theme,
    bool isDark,
  ) {
    final success = widget.isCorrect ?? false;
    final lives = (state is EliteMasteryLoaded) ? state.livesRemaining : 3;
    final primaryGradient = success
        ? [const Color(0xFF2DD4BF), const Color(0xFF10B981)]
        : [const Color(0xFFF43F5E), const Color(0xFFE11D48)];
    final shadowColor = success
        ? const Color(0xFF10B981)
        : const Color(0xFFE11D48);
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = success ? "EXCELLENT!" : "NOT QUITE!";
    String? correctAnswerText;
    final showCorrectAnswer = !success && (state as EliteMasteryLoaded).isFinalFailure;
    final buttonText = success 
        ? "CONTINUE" 
        : ((state as EliteMasteryLoaded).isFinalFailure 
            ? (lives == 0 ? "SEE RESULTS" : "CONTINUE") 
            : "TRY AGAIN");

    if (showCorrectAnswer) {
      final q = state.currentQuest;
      if (q.subtype == GameSubtype.storyBuilder &&
          q.sentences != null &&
          q.correctOrder != null) {
        // Reconstruct full story for guidance
        correctAnswerText = q.correctOrder!
            .map((idx) => q.sentences![idx])
            .join(" → ");
      } else if (q.subtype == GameSubtype.idiomMatch && 
                 q.options != null && 
                 q.correctAnswerIndex != null) {
        // For Idiom Match, the answer is the meaning in the options
        correctAnswerText = q.options![q.correctAnswerIndex!];
      } else {
        correctAnswerText = q.word ?? q.correctAnswer;
        if (correctAnswerText == null &&
            q.options != null &&
            q.correctAnswerIndex != null) {
          correctAnswerText = q.options![q.correctAnswerIndex!];
        }
      }
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: primaryGradient),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28.r),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: primaryGradient,
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (correctAnswerText != null) ...[
            SizedBox(height: 16.h),
            Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: shadowColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: shadowColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: shadowColor, size: 14.r),
                          SizedBox(width: 8.w),
                          Text("EXPLANATION:", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w800, color: shadowColor, letterSpacing: 1)),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(correctAnswerText, style: GoogleFonts.fredoka(fontSize: 18.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms)
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
          ],
          SizedBox(height: 28.h),
          ScaleButton(
            onTap: widget.onContinue,
            child: Container(
              width: double.infinity,
              height: 65.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: primaryGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  buttonText,
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ).animate().scale(
            delay: 500.ms,
            duration: 400.ms,
            curve: Curves.elasticOut,
          ),
        ],
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      curve: Curves.easeOutCubic,
      duration: 500.ms,
    );
  }

  VowlMascotState _getMascotState(
    EliteMasteryState state,
    int lives,
    bool isAnswered,
    bool? isCorrect,
  ) {
    if (state is EliteMasteryGameComplete) return VowlMascotState.happy;
    if (state is EliteMasteryGameOver) return VowlMascotState.worried;
    if (isAnswered) {
      if (isCorrect == true) return VowlMascotState.happy;
      return VowlMascotState.thinking;
    }
    return VowlMascotState.neutral;
  }
}
