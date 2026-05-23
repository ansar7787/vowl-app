import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

// Highly interactive Scratch Card Painter creating a beautiful procedural scratching foil effect
class ScratchPainter extends CustomPainter {
  final double progress;
  final bool isListening;
  final double time;

  ScratchPainter({
    required this.progress,
    required this.isListening,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 0.98) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw metallic silver-grey base foil layer
    final Paint foilPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade400,
          Colors.grey.shade600,
          Colors.grey.shade500,
          Colors.grey.shade300,
          Colors.grey.shade600,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRect(rect, foilPaint);

    // Draw high-fidelity brushed metal diagonal textures
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.w;

    for (double i = -size.height; i < size.width; i += 12.w) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }

    // Procedural Scratching: Clear the canvas based on progress
    final Paint clearPaint = Paint()..blendMode = BlendMode.clear;
    
    // Create organic scratching path
    final path = Path();
    final double step = size.width * progress;

    if (progress > 0) {
      path.moveTo(0, 0);
      path.lineTo(step, 0);
      
      // Scratch border turbulence
      for (double y = 0; y <= size.height; y += 10.h) {
        final double wobble = math.sin(time * 30 + y * 0.1) * 8.w;
        path.lineTo(step + wobble, y);
      }
      
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, clearPaint);

      // Draw burning neon plasma edge at the scratch boundary
      final Paint boundaryGlow = Paint()
        ..color = Colors.amberAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.w
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.r);

      final Paint boundaryCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5.w;

      final Path boundaryPath = Path();
      boundaryPath.moveTo(step, 0);
      for (double y = 0; y <= size.height; y += 8.h) {
        final double wobble = math.sin(time * 30 + y * 0.1) * 8.w;
        boundaryPath.lineTo(step + wobble, y);
      }

      canvas.drawPath(boundaryPath, boundaryGlow);
      canvas.drawPath(boundaryPath, boundaryCore);
    }
  }

  @override
  bool shouldRepaint(covariant ScratchPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.time != time;
  }
}

class DailyExpressionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const DailyExpressionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dailyExpression,
  });

  @override
  State<DailyExpressionScreen> createState() => _DailyExpressionScreenState();
}

class _DailyExpressionScreenState extends State<DailyExpressionScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  double _scratchProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  // Animation controller for edge glow oscillation
  late AnimationController _glowController;
  Timer? _scratchTimer;
  double _timeVal = 0.0;
  String _spokenText = "";
  String _targetExpression = "";

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {
          _timeVal = _glowController.value;
        });
      });
    _glowController.repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scratchTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.expression != null) {
      _soundService.playTts(quest.expression!);
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _scratchProgress = 0.05;
      _spokenText = "Initializing vocal frequency analyzer...";
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );

    // Dynamic procedural scratch scraping speed mapping
    _scratchTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_scratchProgress < 0.90) {
          _scratchProgress += 0.012 + (math.Random().nextDouble() * 0.008);
        } else {
          _scratchProgress = 0.90 + (math.Random().nextDouble() * 0.02);
        }
      });
    });
  }

  void _stopSpeechListening() async {
    _scratchTimer?.cancel();
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifyExpressionSpoken();
  }

  void _verifyExpressionSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Initializing")) {
      setState(() {
        _spokenText = "Vocal analysis timed out.";
        _scratchProgress = 0.0;
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final String cleanExpression = _targetExpression.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // High fidelity phonetic alignment: does the speech match or contain the target idiom?
    final bool matchFound = cleanSpeech.contains(cleanExpression) || cleanExpression.contains(cleanSpeech);

    setState(() {
      _isAnswered = true;
      _isCorrect = matchFound;
      _scratchProgress = matchFound ? 1.0 : 0.0;
    });

    if (matchFound) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _scratchProgress = 0.0;
              _spokenText = "";
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'EXPRESSION MASTERED!',
            enableDoubleUp: true,
          );
        } else if (state is SpeakingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<SpeakingBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        if (quest != null) {
          _targetExpression = quest.expression ?? "Idiom";
        }

        return SpeakingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
          onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      _buildHeaderPill(theme.primaryColor),
                      SizedBox(height: 16.h),

                      // Holographic Scratch Card panel
                      _buildScratchPanel(quest, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Context rich usage quote plate
                      if (_scratchProgress > 0.3)
                        _buildUsagePanel(quest, theme.primaryColor, isDark)
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1),
                      SizedBox(height: 20.h),

                      // Real-time telemetry feed
                      if (_spokenText.isNotEmpty) ...[
                        _buildFrequencyTelemetryCard(isDark),
                        SizedBox(height: 20.h),
                      ],

                      // Explanations details
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 30.h),

                      // Interactive scratch mic
                      if (!_isAnswered)
                        _buildScratcherTrigger(theme.primaryColor, isDark),
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderPill(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14.r, color: Colors.amberAccent),
          SizedBox(width: 8.w),
          Text(
            "TACTILE FOIL SCRATCH CARD",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchPanel(SpeakingQuest quest, Color primaryColor, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: 1.sw,
        height: 190.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131326) : Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15.r,
            )
          ],
        ),
        child: Stack(
          children: [
            // Underlying Revealed Golden Card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1E38), const Color(0xFF111124)]
                        : [Colors.amber.shade50.withValues(alpha: 0.2), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.all(22.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "DAILY IDIOM",
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10.sp,
                            color: Colors.amberAccent,
                            letterSpacing: 1.5,
                          ),
                        ),
                        ScaleButton(
                          onTap: () => _soundService.playTts(quest.expression ?? ""),
                          child: Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 18.r),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      quest.expression ?? "Bite the bullet",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.amberAccent,
                        shadows: [
                          Shadow(
                            color: Colors.amberAccent.withValues(alpha: 0.3),
                            blurRadius: 10.r,
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      (quest.meaning ?? "Meaning").toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // Scratch Foil Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: ScratchPainter(
                  progress: _scratchProgress,
                  isListening: _isListening,
                  time: _timeVal,
                ),
              ),
            ),

            // Scratch Instructions Overlay
            if (_scratchProgress == 0.0)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swipe_rounded, color: Colors.white, size: 30.r)
                            .animate(onPlay: (c) => c.repeat())
                            .shake(hz: 2, curve: Curves.easeInOut)
                            .then()
                            .fadeOut(),
                        SizedBox(height: 8.h),
                        Text(
                          "SPOKEN FREQUENCY DISSOLVES FOIL",
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsagePanel(SpeakingQuest quest, Color primaryColor, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.format_quote_rounded, color: Colors.amberAccent, size: 16.r),
              SizedBox(width: 8.w),
              Text(
                "CONTEXTUAL SAMPLE USAGE",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            "\"${quest.sampleUsage ?? 'Sample usage'}\"",
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 16.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyTelemetryCard(bool isDark) {
    final bool hasInput = _spokenText != "Initializing vocal frequency analyzer..." && _spokenText != "Vocal analysis timed out.";

    return GlassTile(
      padding: EdgeInsets.all(18.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hasInput ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: Colors.amberAccent,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "TRANSCRIBED IDIOMATIC PHRASE",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            _spokenText,
            style: GoogleFonts.fredoka(
              fontSize: 15.sp,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildExplanationCard(SpeakingQuest quest, bool isDark) {
    final Color cardColor = (_isCorrect ?? false) ? Colors.amberAccent : Colors.redAccent;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                (_isCorrect ?? false) ? Icons.verified_rounded : Icons.info_rounded,
                color: cardColor,
                size: 24.r,
              ),
              SizedBox(width: 8.w),
              Text(
                (_isCorrect ?? false) ? "Card Fully Scratched!" : "Foil Remains Unbroken",
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            quest.explanation ?? "Understanding historical contexts of colloquial idioms strengthens language native depth.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildScratcherTrigger(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _startSpeechListening(),
      onLongPressEnd: (_) => _stopSpeechListening(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Beautiful glowing golden star particles emitting while recording is active
              if (_isListening)
                ...List.generate(8, (i) {
                  final double angle = (i * math.pi * 2) / 8 + (_timeVal * 15.0);
                  final double dist = 60.w + (math.sin(_timeVal * 20.0 + i) * 15.w);
                  return Positioned(
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.amberAccent.withValues(alpha: 0.8),
                      size: (12.r + i * 2.r).clamp(10, 24).toDouble(),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .move(
                      begin: Offset.zero,
                      end: Offset(math.cos(angle) * dist, -50.h + math.sin(angle) * dist * 0.4),
                      duration: (400 + i * 80).ms,
                      curve: Curves.easeOut,
                    )
                    .fadeOut(),
                  );
                }),

              // Outer aura ring
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: _isListening
                        ? Colors.amberAccent.withValues(alpha: 0.3)
                        : primaryColor.withValues(alpha: 0.1),
                    width: 4.r,
                  ),
                ),
              ).animate(target: _isListening ? 1 : 0).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.18, 1.18),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  ),

              // Sizzling inner watering can core
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [Colors.amber[800]!, Colors.amberAccent]
                          : [const Color(0xFF2C3E50), const Color(0xFF000000)],
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: Colors.amberAccent.withValues(alpha: 0.45),
                              blurRadius: 25.r,
                              spreadRadius: 2.r,
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10.r,
                            )
                          ],
                  ),
                  child: Icon(
                    _isListening ? Icons.auto_fix_normal_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _isListening ? "RELEASE CAN TO REVEAL CARD" : "HOLD COIN TO VOICE-SCRATCH CARD",
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              fontSize: 9.sp,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
