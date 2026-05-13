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
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_header.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/presentation/painters/visual_config_background.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_error_view.dart';

class VocabularyBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final bool isFinalFailure;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final bool useScrolling;
  final bool disablePadding;

  const VocabularyBaseLayout({
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
    this.useScrolling = true,
    this.disablePadding = false,
  });

  @override
  State<VocabularyBaseLayout> createState() => _VocabularyBaseLayoutState();
}

class _VocabularyBaseLayoutState extends State<VocabularyBaseLayout> {
  final _ttsService = di.sl<TtsService>();
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
    final theme = LevelThemeHelper.getTheme(widget.gameType.name, isDark: isDark);

    return BlocListener<VocabularyBloc, VocabularyState>(
      listenWhen: (previous, current) {
        if (current is VocabularyLoaded) {
          if (previous is! VocabularyLoaded) return true;
          return previous.currentIndex != current.currentIndex ||
              previous.livesRemaining != current.livesRemaining;
        }
        return false;
      },
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          // Detect the exact transition from 2 lives to 1 life
          final justDroppedToLastLife = _lastLives == 2 && state.livesRemaining == 1;
          
          if (state.currentIndex != _lastIndex) {
            _lastIndex = state.currentIndex;
          }

          if (justDroppedToLastLife && !_hasSpokenNudge) {
            _hasSpokenNudge = true; // Permanent for this session
            // Delay to allow the "Wrong" sound effect to finish
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (!context.mounted) return;
              _ttsService.speak(
                "Oh no! Use a hint to save your life!",
              );
              di.sl<HapticService>().warning();
            });
          }
          
          _lastLives = state.livesRemaining;
        }
      },
      child: BlocBuilder<VocabularyBloc, VocabularyState>(
        builder: (context, state) {
          final isComplete = state is VocabularyGameComplete;
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
                final progress = (state is VocabularyLoaded)
                    ? (state.currentIndex + 1) / state.quests.length
                    : (state is VocabularyGameComplete ? 1.0 : 0.0);
                final lives = (state is VocabularyLoaded) ? state.livesRemaining : 3;
                final currentQuest = (state is VocabularyLoaded) ? state.currentQuest : null;

                return Scaffold(
                  backgroundColor: theme.backgroundColors[1],
                  body: Stack(
                    children: [
                      Container(color: theme.backgroundColors[1]), // Prevent white splash
                      MeshGradientBackground(colors: theme.backgroundColors),
                      if (currentQuest != null && currentQuest.visualConfig != null)
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: VisualConfigBackground(config: currentQuest.visualConfig!),
                          ),
                        ),
                      if (state is VocabularyError)
                        VocabularyErrorView(
                          message: state.message,
                          primaryColor: theme.primaryColor,
                          onRetry: () {
                            context.read<VocabularyBloc>().add(
                              FetchVocabularyQuests(
                                gameType: widget.gameType,
                                level: widget.level,
                              ),
                            );
                          },
                        )
                      else ...[
                        SafeArea(
                          child: Column(
                            children: [
                              SizedBox(height: 10.h),
                              _buildCustomHeader(context, state, widget.level, progress, lives, theme, isDark, currentQuest),
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
                                                key: const ValueKey('vocab_layout_scroller'),
                                                builder: (context, constraints) {
                                                  return SingleChildScrollView(
                                                    physics: const BouncingScrollPhysics(),
                                                    child: ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        minHeight: constraints.maxHeight,
                                                        maxWidth: constraints.maxWidth,
                                                      ),
                                                      child: Padding(
                                                        padding: EdgeInsets.only(
                                                          left: widget.disablePadding ? 0 : 24.w,
                                                          right: widget.disablePadding ? 0 : 24.w,
                                                          top: widget.disablePadding ? 0 : 40.h,
                                                          bottom: widget.isAnswered ? 200.h : (widget.disablePadding ? 0 : 40.h),
                                                        ),
                                                        child: widget.child,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Padding(
                                                padding: EdgeInsets.only(
                                                  left: widget.disablePadding ? 0 : 24.w,
                                                  right: widget.disablePadding ? 0 : 24.w,
                                                  top: widget.disablePadding ? 0 : 40.h,
                                                  bottom: widget.isAnswered ? 200.h : (widget.disablePadding ? 0 : 40.h),
                                                ),
                                                child: widget.child,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -10.h, left: 20.w,
                                      child: _buildPeekingMascot(state, lives),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (widget.isAnswered && widget.isCorrect != null && state is! VocabularyGameOver && state is! VocabularyGameComplete)
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: _buildModernFeedbackCard(context, state, theme, isDark),
                        ),
                      if (_showBriefing)
                        Builder(
                          builder: (context) {
                            final briefing = GameInstructionService.getBriefing(widget.gameType, "Vocabulary", level: widget.level);
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
                      if (widget.showConfetti) const GameConfetti(),
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

  Widget _buildCustomHeader(BuildContext context, VocabularyState state, int level, double progress, int lives, dynamic theme, bool isDark, VocabularyQuest? quest) {
    final hintShouldGlow = lives < 3 && !widget.isAnswered;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: FlashcardHeader(
              level: level, progress: progress, lives: lives,
              streak: (state is VocabularyLoaded) ? state.currentIndex : 0,
              theme: theme, isDark: isDark,
              onBack: () => GameDialogHelper.showExitConfirmation(this.context, onQuit: () => Navigator.pop(this.context)),
            ),
          ),
          
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
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.info_outline_rounded, size: 16.r, color: theme.primaryColor),
              ),
            ),
          ),

          if (quest != null && !widget.isAnswered)
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: QuestHintButton(
                used: (state is VocabularyLoaded) ? state.hintUsed : false,
                primaryColor: theme.primaryColor,
                hintText: widget.gameType == GameSubtype.topicVocab ? null : quest.hint,
                soundService: di.sl<SoundService>(),
                onTap: () {
                  context.read<VocabularyBloc>().add(VocabularyHintUsed());
                  context.read<EconomyBloc>().add(const EconomyConsumeHintRequested());
                  widget.onHint();
                },
              ).animate(target: hintShouldGlow ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
               .shimmer(color: Colors.white.withValues(alpha: 0.5), duration: 1.seconds)
               .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            ),
        ],
      ),
    );
  }

  Widget _buildPeekingMascot(VocabularyState state, int lives) {
    final mascotState = _getMascotState(state, lives);
    final authState = context.read<AuthBloc>().state;
    final mascotId = authState.user?.vowlMascot ?? 'vowl_prime';
    final mascotName = mascotId.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');

    String message = "Look closely!";
    if (widget.isCorrect == true) {
      message = "Brilliant! ✨";
    } else if (lives < 3 && !widget.isAnswered) {
      message = "Help! Use a hint! 💡";
    } else if (widget.isCorrect == false) {
      message = "Try again! 💡";
    } else if (state is VocabularyGameComplete) {
      message = "Mastered! 🏆";
    } else {
      message = "$mascotName is watching! 🦉";
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
          ),
          child: Text(message, style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.indigo)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
        SizedBox(height: 0.h),
        VowlMascot(state: mascotState, size: 45.r).animate(onPlay: (c) => c.repeat(reverse: true))
         .moveY(begin: 0, end: 8, duration: 1200.ms, curve: Curves.easeInOut)
         .rotate(begin: -0.05, end: 0.05, duration: 2.seconds),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildModernFeedbackCard(BuildContext context, VocabularyState state, dynamic theme, bool isDark) {
    if (state is! VocabularyLoaded) return const SizedBox();
    final loadedState = state;
    
    final success = widget.isCorrect ?? false;
    final lives = loadedState.livesRemaining;
    final primaryGradient = success ? [const Color(0xFF2DD4BF), const Color(0xFF10B981)] : [const Color(0xFFF43F5E), const Color(0xFFE11D48)];
    final shadowColor = success ? const Color(0xFF10B981) : const Color(0xFFE11D48);
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = success ? "EXCELLENT!" : "NOT QUITE!";
    final showCorrectAnswer = !success && loadedState.isFinalFailure;
    final buttonText = success 
        ? "CONTINUE" 
        : (loadedState.isFinalFailure 
            ? (lives == 0 ? "SEE RESULTS" : "CONTINUE") 
            : "TRY AGAIN");

    String? correctAnswerText;
    if (showCorrectAnswer) {
      final q = loadedState.currentQuest;
      if (q.interactionType == InteractionType.flip) {
        correctAnswerText = q.meaning;
      } else if (q.correctAnswerIndex != null && q.options != null && q.correctAnswerIndex! < q.options!.length) {
        correctAnswerText = q.options![q.correctAnswerIndex!];
      } else {
        correctAnswerText = q.correctAnswer ?? q.word;
      }
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
          if (correctAnswerText != null) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity, padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(color: shadowColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: shadowColor.withValues(alpha: 0.2), width: 1.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CORRECT ANSWER:", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w800, color: shadowColor, letterSpacing: 1)),
                  SizedBox(height: 4.h),
                  Text(correctAnswerText, style: GoogleFonts.fredoka(fontSize: 20.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).scale(duration: 400.ms, curve: Curves.easeOutBack),
          ],
          
          // NEW: Explanation Field
          if (loadedState.currentQuest.explanation != null && (success || loadedState.isFinalFailure)) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity, padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18.r, color: shadowColor.withValues(alpha: 0.7)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      loadedState.currentQuest.explanation!,
                      style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black54, height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
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

  VowlMascotState _getMascotState(VocabularyState state, int lives) {
    if (state is VocabularyGameComplete) return VowlMascotState.happy;
    if (state is VocabularyGameOver) return VowlMascotState.worried;
    if (state is VocabularyLoaded) {
      if (widget.isCorrect == true) return VowlMascotState.happy;
      if (lives < 3 && !widget.isAnswered) return VowlMascotState.worried;
      if (widget.isCorrect == false) return VowlMascotState.thinking;
    }
    return VowlMascotState.neutral;
  }
}

class VocabularyQuestionCard extends StatelessWidget {
  final VocabularyQuest quest;
  final dynamic theme;
  final bool isDark;
  const VocabularyQuestionCard({super.key, required this.quest, required this.theme, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(24.r), border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 1.5)),
      child: Column(
        children: [
          Row(children: [Expanded(child: Text(quest.instruction.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w800, color: theme.primaryColor, letterSpacing: 2)))]),
          SizedBox(height: 12.h),
          Text(quest.word ?? quest.prompt ?? "Quest", textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 28.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
          if (quest.sentence != null) ...[
            SizedBox(height: 12.h),
            Text(quest.sentence!, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 15.sp, color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.7), fontStyle: FontStyle.italic, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
