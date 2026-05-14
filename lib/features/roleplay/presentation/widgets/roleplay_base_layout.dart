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
import 'package:vowl/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_header.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';

class RoleplayBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final bool isFinalFailure;
  final String title;
  final String subtitle;
  final ScrollController? scrollController;
  final bool useScrolling;
  final bool disablePadding;

  const RoleplayBaseLayout({
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
    this.title = "SOCIAL SCENARIO",
    this.subtitle = "Master the Scene",
    this.scrollController,
    this.useScrolling = true,
    this.disablePadding = false,
  });

  @override
  State<RoleplayBaseLayout> createState() => _RoleplayBaseLayoutState();
}

class _RoleplayBaseLayoutState extends State<RoleplayBaseLayout> {
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
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocListener<RoleplayBloc, RoleplayState>(
      listenWhen: (previous, current) {
        if (current is RoleplayLoaded) {
          if (previous is! RoleplayLoaded) return true;
          return previous.currentIndex != current.currentIndex ||
              previous.livesRemaining != current.livesRemaining;
        }
        return false;
      },
      listener: (context, state) {
        if (state is RoleplayLoaded) {
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
      child: BlocBuilder<RoleplayBloc, RoleplayState>(
        builder: (context, state) {
          final isComplete = state is RoleplayGameComplete;
          if (state is RoleplayError) {
            return Scaffold(
            resizeToAvoidBottomInset: false,
              backgroundColor: theme.backgroundColors[1],
              body: GameErrorWidget(
                message: state.message,
                onRetry: () => context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level)),
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
                final progress = (state is RoleplayLoaded)
                    ? (state.currentIndex + 1) / state.quests.length
                    : (state is RoleplayGameComplete ? 1.0 : 0.0);
                final lives = (state is RoleplayLoaded) ? state.livesRemaining : 3;
                final currentQuest = (state is RoleplayLoaded) ? state.currentQuest : null;

                return Scaffold(
            backgroundColor: theme.backgroundColors[1],
            body: Stack(
              children: [
                Container(color: theme.backgroundColors[1]), // Prevent white splash
                MeshGradientBackground(colors: theme.backgroundColors),
                HarmonicWaves(color: theme.primaryColor.withValues(alpha: 0.3), height: 150.h),
                if (state is RoleplayLoading) GameShimmerLoading(primaryColor: theme.primaryColor)
                else ...[
                  SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        _buildHeader(context, state, widget.level, progress, lives, theme, isDark, currentQuest),
                        
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 400),
                                opacity: widget.isAnswered ? 0.6 : 1.0,
                                child: AbsorbPointer(
                                  absorbing: widget.isAnswered,
                                child: widget.useScrolling
                                  ? LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          controller: widget.scrollController,
                                          physics: const BouncingScrollPhysics(),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                left: widget.disablePadding ? 0 : 20.w,
                                                right: widget.disablePadding ? 0 : 20.w,
                                                top: widget.disablePadding ? 0 : 20.h,
                                                bottom: (widget.disablePadding ? 0 : (widget.isAnswered ? 200.h : 40.h)) + MediaQuery.of(context).viewInsets.bottom,
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(widget.title, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, letterSpacing: 4, color: theme.primaryColor)).animate().fadeIn(),
                                                  SizedBox(height: 8.h),
                                                  Text(widget.subtitle, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))).animate().fadeIn().slideY(begin: 0.1),
                                                  SizedBox(height: 32.h),
                                                  widget.child,
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Padding(
                                      padding: EdgeInsets.only(
                                        left: widget.disablePadding ? 0 : 20.w,
                                        right: widget.disablePadding ? 0 : 20.w,
                                        top: widget.disablePadding ? 0 : 20.h,
                                        bottom: (widget.disablePadding ? 0 : (widget.isAnswered ? 200.h : 40.h)) + MediaQuery.of(context).viewInsets.bottom,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(widget.title, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, letterSpacing: 4, color: theme.primaryColor)).animate().fadeIn(),
                                          SizedBox(height: 8.h),
                                          Text(widget.subtitle, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))).animate().fadeIn().slideY(begin: 0.1),
                                          SizedBox(height: 32.h),
                                          widget.child,
                                        ],
                                      ),
                                    ),
                                ),
                              ),
                              Positioned(
                                top: -10.h, right: 10.w,
                                child: _buildPeekingMascot(state, lives),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.isAnswered && state is! RoleplayGameOver && state is! RoleplayGameComplete)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: _buildFeedbackCard(context, state, theme, isDark),
                  ),
                if (widget.showConfetti) const GameConfetti(),

                if (_showBriefing)
                  Builder(
                    builder: (context) {
                      final briefing = GameInstructionService.getBriefing(widget.gameType, "Roleplay", level: widget.level);
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
    );
  },
),
    );
}

  Widget _buildHeader(BuildContext context, RoleplayState state, int level, double progress, int lives, dynamic theme, bool isDark, dynamic quest) {
    final hintShouldGlow = lives < 3 && !widget.isAnswered;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: FlashcardHeader(
              level: level, progress: progress, lives: lives,
              streak: (state is RoleplayLoaded) ? state.currentIndex : 0,
              theme: theme, isDark: isDark,
              onBack: () => GameDialogHelper.showExitConfirmation(this.context, onQuit: () => Navigator.pop(this.context)),
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
              child: QuestHintButton(
                used: (state is RoleplayLoaded) ? state.hintUsed : false,
                primaryColor: theme.primaryColor,
                hintText: quest.hint,
                soundService: _soundService,
                onTap: () {
                  context.read<RoleplayBloc>().add(RoleplayHintUsed());
                  widget.onHint();
                },
              ).animate(target: hintShouldGlow ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
               .shimmer(color: Colors.white.withValues(alpha: 0.5), duration: 1.seconds)
               .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeekingMascot(RoleplayState state, int lives) {
    final mascotState = _getMascotState(state, lives);
    final authState = context.read<AuthBloc>().state;
    final mascotId = authState.user?.vowlMascot ?? 'vowl_prime';
    final mascotName = mascotId.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');

    String message = "Good luck! 🎭";
    if (widget.isCorrect == true) {
      message = "Social Pro! ✨";
    } else if (lives < 3 && !widget.isAnswered) {
      message = "Check the hints! 💡";
    } else if (widget.isCorrect == false) {
      message = "One more try! 🎤";
    } else if (state is RoleplayGameComplete) {
      message = "Charisma King! 🏆";
    } else {
      message = "$mascotName is watching! 🦉";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
          ),
          child: Text(message, style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
        SizedBox(height: 0.h),
        VowlMascot(state: mascotState, size: 45.r, mascotId: mascotId).animate(onPlay: (c) => c.repeat(reverse: true))
         .moveY(begin: 0, end: 5, duration: 1500.ms, curve: Curves.easeInOut),
      ],
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildFeedbackCard(BuildContext context, RoleplayState state, dynamic theme, bool isDark) {
    final success = widget.isCorrect ?? false;
    final lives = (state is RoleplayLoaded) ? state.livesRemaining : 3;
    final primaryGradient = success ? [const Color(0xFF2DD4BF), const Color(0xFF10B981)] : [const Color(0xFFF43F5E), const Color(0xFFE11D48)];
    final shadowColor = success ? const Color(0xFF10B981) : const Color(0xFFE11D48);
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = success ? "EXCELLENT!" : "NOT QUITE!";
    final showCorrectAnswer = !success && (state as RoleplayLoaded).isFinalFailure;
    final buttonText = success 
        ? "CONTINUE" 
        : ((state as RoleplayLoaded).isFinalFailure 
            ? (lives == 0 ? "SEE RESULTS" : "CONTINUE") 
            : "TRY AGAIN");

    String? explanation;
    if (showCorrectAnswer) {
      explanation = state.currentQuest.explanation;
    }

    return Container(
      width: double.infinity, padding: EdgeInsets.all(28.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        boxShadow: [BoxShadow(color: shadowColor.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(gradient: LinearGradient(colors: primaryGradient), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 28.r),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              SizedBox(width: 16.w),
              Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.w900, foreground: Paint()..shader = LinearGradient(colors: primaryGradient).createShader(const Rect.fromLTWH(0, 0, 200, 70)), letterSpacing: 1.5))),
            ],
          ),
          if (explanation != null) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity, padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(color: shadowColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: shadowColor.withValues(alpha: 0.2), width: 1.5)),
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
                  Text(explanation, style: GoogleFonts.fredoka(fontSize: 18.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).scale(duration: 400.ms, curve: Curves.easeOutBack),
          ],
          SizedBox(height: 28.h),
          ScaleButton(
            onTap: widget.onContinue,
            child: Container(
              width: double.infinity, height: 65.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: primaryGradient),
                boxShadow: [BoxShadow(color: shadowColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
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
          ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.elasticOut),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic, duration: 500.ms);
  }

  VowlMascotState _getMascotState(RoleplayState state, int lives) {
    if (state is RoleplayGameComplete) return VowlMascotState.happy;
    if (state is RoleplayGameOver) return VowlMascotState.worried;
    if (state is RoleplayLoaded) {
      if (widget.isCorrect == true) return VowlMascotState.happy;
      if (widget.isCorrect == false) return VowlMascotState.thinking;
    }
    return VowlMascotState.neutral;
  }
}
