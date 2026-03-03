import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/modern_game_dialog.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:confetti/confetti.dart';

class IntonationMimicScreen extends StatefulWidget {
  final int level;
  const IntonationMimicScreen({super.key, required this.level});

  @override
  State<IntonationMimicScreen> createState() => _IntonationMimicScreenState();
}

class _IntonationMimicScreenState extends State<IntonationMimicScreen> {
  final _speechService = di.sl<SpeechService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _isPlaying = false;
  bool _showConfetti = false;

  // Pitch Wave Trace state
  double _traceProgress = 0.0;
  bool _isTracing = false;
  bool _traceCompleted = false;

  late ConfettiController _confettiController;
  AccentLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _speechService.initializeStt();
    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: GameSubtype.intonationMimic,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
      _traceProgress = 0.0; // Reset trace on replay
      _traceCompleted = false;
    });
    _hapticService.light();
    // Removed _soundService.playClick() to prevent double sound
    await _speechService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onTraceUpdate(DragUpdateDetails details, double maxWidth) {
    if (_traceCompleted || _isPlaying) {
      return; // Prevent tracing while audio plays
    }

    setState(() {
      _isTracing = true;
      // Calculate progress based on horizontal drag across the container
      _traceProgress += details.primaryDelta! / maxWidth;
      _traceProgress = _traceProgress.clamp(0.0, 1.0);
    });

    // Provide continuous haptic feedback during successful tracing
    if (_traceProgress > 0 &&
        _traceProgress < 1.0 &&
        DateTime.now().millisecond % 100 < 16) {
      _hapticService.light();
    }
  }

  void _onTraceEnd(DragEndDetails details) {
    setState(() => _isTracing = false);
    if (_traceProgress > 0.85) {
      // Threshold for completion
      _completeTrace();
    } else {
      // Snap back if didn't finish
      setState(() => _traceProgress = 0.0);
      _hapticService.error();
      _soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _completeTrace() {
    if (_traceCompleted) return;
    setState(() {
      _traceProgress = 1.0;
      _traceCompleted = true;
    });

    _hapticService.success();
    _soundService.playCorrect();
    context.read<AccentBloc>().add(SubmitAnswer(true));

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        context.read<AccentBloc>().add(NextQuestion());
      }
    });
  }

  void _useHint(AccentLoaded state) {
    if (state.hintUsed) {
      _hapticService.error();
      return;
    }
    _hapticService.selection();
    _soundService.playHint();
    setState(() {
      _traceProgress = (_traceProgress + 0.35).clamp(0.0, 1.0);
    });
    context.read<AccentBloc>().add(AccentHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF8FAFC),
      body: BlocConsumer<AccentBloc, AccentState>(
        listener: (context, state) {
          if (state is AccentGameComplete) {
            _confettiController.play();
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => _showCompletionDialog(
                context,
                state.xpEarned,
                state.coinsEarned,
              ),
            );
          } else if (state is AccentGameOver) {
            _showGameOverDialog(context);
          } else if (state is AccentLoaded) {
            _lastLoadedState = state;
            if (state.lastAnswerCorrect == null) {
              setState(() {
                _traceProgress = 0.0;
                _traceCompleted = false;
                _isTracing = false;
              });
            } else if (state.lastAnswerCorrect == false) {
              final accentBloc = context.read<AccentBloc>();
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted && state.livesRemaining > 0) {
                  // Auto-dismiss the error loop safely without resetting the trace progress manually before restore
                  if (mounted) {
                    accentBloc.add(RestoreLife());
                  }
                }
              });
            }
          }
        },
        builder: (context, state) {
          if (state is AccentLoading ||
              (state is AccentInitial && _lastLoadedState == null)) {
            return const GameShimmerLoading();
          }

          if (state is AccentError) {
            final accentBloc = context.read<AccentBloc>();
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => accentBloc.add(
                FetchAccentQuests(
                  gameType: GameSubtype.intonationMimic,
                  level: widget.level,
                ),
              ),
            );
          }

          final displayState = state is AccentLoaded ? state : _lastLoadedState;

          if (displayState != null) {
            final theme = LevelThemeHelper.getTheme(
              'accent',
              level: widget.level,
              isDark: isDark,
            );
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                HarmonicWaves(color: theme.primaryColor, height: 100),
                _buildGameUI(context, displayState, isDark, theme),
                if (_showConfetti)
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [
                        Colors.amber,
                        Colors.blue,
                        Colors.pink,
                        Colors.orange,
                        Colors.purple,
                      ],
                    ),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGameUI(
    BuildContext context,
    AccentLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 10.h),
              child: Row(
                children: [
                  ScaleButton(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 24.r,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14.h,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  if (!state.hintUsed) ...[
                    _buildHintButton(state, theme.primaryColor),
                    SizedBox(width: 12.w),
                  ],
                  _buildHeartCount(state.livesRemaining),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      theme.title,
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 40.h),

                    // Main Phrase Card
                    GlassTile(
                      padding: EdgeInsets.all(40.r),
                      borderRadius: BorderRadius.circular(40.r),
                      borderColor: theme.primaryColor.withValues(alpha: 0.3),
                      color: isDark
                          ? theme.primaryColor.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.5),
                      child: Column(
                        children: [
                          ScaleButton(
                            onTap: () => _playAudio(quest.word ?? ""),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 16.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primaryColor.withValues(alpha: 0.9),
                                    theme.primaryColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isPlaying)
                                    const HarmonicWaves(
                                      color: Colors.white,
                                      height: 30,
                                    ).animate().fadeIn()
                                  else
                                    Icon(
                                      Icons.volume_up_rounded,
                                      color: Colors.white,
                                      size: 28.r,
                                    ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    "LISTEN",
                                    style: GoogleFonts.outfit(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 32.h),
                          Text(
                            quest.word ?? "Perfect practice makes perfect.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: 1.2,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                    SizedBox(height: 40.h),

                    Text(
                      quest.instruction,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black87,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Interactive Pitch Wave Trace Area
                    Text(
                      "LISTEN. THEN DRAG THE PUCK STRONGLY RIGHT TO TRACE.",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    if (state.lastAnswerCorrect == null)
                      _buildPitchTraceComponent(theme, isDark)
                    else
                      SizedBox(height: 120.h), // Placeholder when answered

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildPitchTraceComponent(ThemeResult theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _onTraceUpdate(details, maxWidth),
          onHorizontalDragEnd: _onTraceEnd,
          child: Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background Wave Pattern
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: CustomPaint(
                      painter: _PitchWavePainter(
                        progress: _traceProgress,
                        color: theme.primaryColor.withValues(alpha: 0.3),
                        activeColor: theme.primaryColor,
                      ),
                    ),
                  ),
                ),

                // Tracing Puck
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 50),
                  left: (_traceProgress * (maxWidth - 60.r)).clamp(
                    0.0,
                    maxWidth - 60.r,
                  ),
                  child:
                      Container(
                            width: 60.r,
                            height: 60.r,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: _isTracing ? 16 : 8,
                                  spreadRadius: _isTracing ? 4 : 0,
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(
                              _traceCompleted
                                  ? Icons.check_rounded
                                  : Icons.touch_app_rounded,
                              color: Colors.white,
                              size: 28.r,
                            ),
                          )
                          .animate(target: _isTracing ? 1 : 0)
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                          ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildHeartCount(int lives) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20.r),
          SizedBox(width: 6.w),
          Text(
            "$lives",
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: Colors.pinkAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintButton(AccentLoaded state, Color primaryColor) {
    bool disabled = state.hintUsed;
    return ScaleButton(
      onTap: disabled ? null : () => _useHint(state),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.withValues(alpha: 0.1)
              : primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: disabled
                ? Colors.grey.withValues(alpha: 0.3)
                : primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              disabled
                  ? Icons.lightbulb_outline_rounded
                  : Icons.lightbulb_rounded,
              color: disabled ? Colors.grey : primaryColor,
              size: 20.r,
            ),
            SizedBox(width: 6.w),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final hintCount = authState.user?.hintCount ?? 0;
                return Text(
                  "$hintCount",
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: disabled ? Colors.grey : primaryColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, int xp, int coins) {
    _soundService.playLevelComplete();
    _hapticService.success();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => ModernGameDialog(
        title: 'Rhythm Master!',
        description:
            'You earned 5 XP and 10 Coins for your perfect intonation!',
        buttonText: 'AWESOME',
        onButtonPressed: () {
          Navigator.pop(c);
          context.pop();
        },
      ),
    );
  }

  void _showGameOverDialog(BuildContext context) {
    _hapticService.error();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => ModernGameDialog(
        title: 'Silence Reigned',
        description: 'Take a breath and try to feel the melody!',
        buttonText: 'TRY AGAIN',
        isSuccess: false,
        onButtonPressed: () {
          Navigator.pop(c);
          context.read<AccentBloc>().add(RestoreLife());
        },
        secondaryButtonText: 'EXIT',
        onSecondaryPressed: () {
          Navigator.pop(c);
          context.pop();
        },
      ),
    );
  }
}

// Custom Painter for the Pitch Wave Trace background
class _PitchWavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color activeColor;

  _PitchWavePainter({
    required this.progress,
    required this.color,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    final path = Path();
    final activePath = Path();

    // Create a stylized sine-wave look simulating intonation
    final steps = 50;
    final dx = size.width / steps;

    path.moveTo(0, size.height / 2);
    activePath.moveTo(0, size.height / 2);

    for (int i = 0; i <= steps; i++) {
      final x = i * dx;
      // complex arbitrary wave function for 'melody' feeling
      final yOffset = math.sin(i * 0.3) * 20 + math.cos(i * 0.1) * 15;
      final y = size.height / 2 + yOffset;

      if (i == 0) continue;

      path.lineTo(x, y);

      // Draw active path up to current progress
      if (x <= size.width * progress) {
        activePath.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
    if (progress > 0) {
      canvas.drawPath(activePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PitchWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.activeColor != activeColor;
  }
}
