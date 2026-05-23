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

// Gorgeous Condensation Painter creating a beautiful procedural wiping fog effect
class FogPainter extends CustomPainter {
  final double progress;
  final double time;

  FogPainter({
    required this.progress,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 0.98) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw procedural glass fog background
    final Paint fogPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0.88),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final Paint borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.r;

    // Apply frosted blur effect
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(28.r)),
      fogPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(28.r)),
      borderPaint,
    );

    // Procedural Wiping: Clear canvas from left to right based on wipe progress
    final Paint clearPaint = Paint()..blendMode = BlendMode.clear;
    
    final path = Path();
    final double step = size.width * progress;

    if (progress > 0) {
      path.moveTo(0, 0);
      path.lineTo(step, 0);
      
      // Crackling water condensation boundary
      for (double y = 0; y <= size.height; y += 8.h) {
        final double wave = math.sin(time * 24.0 + y * 0.15) * 5.w;
        path.lineTo(step + wave, y);
      }
      
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, clearPaint);

      // Draw sparkling condensation water droplets along the boundary
      final Paint dropletGlow = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.w
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.r);

      final Paint dropletCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2.w;

      final Path dropletPath = Path();
      dropletPath.moveTo(step, 0);
      for (double y = 0; y <= size.height; y += 6.h) {
        final double wave = math.sin(time * 24.0 + y * 0.15) * 5.w;
        dropletPath.lineTo(step + wave, y);
      }

      canvas.drawPath(dropletPath, dropletGlow);
      canvas.drawPath(dropletPath, dropletCore);
    }
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.time != time;
  }
}

class SituationSpeakingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SituationSpeakingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.situationSpeaking,
  });

  @override
  State<SituationSpeakingScreen> createState() => _SituationSpeakingScreenState();
}

class _SituationSpeakingScreenState extends State<SituationSpeakingScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  double _scrubProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  // Animation controller for water droplet shimmer oscillation
  late AnimationController _shimmerController;
  double _timeVal = 0.0;
  String _spokenText = "";
  List<String> _acceptedSubstrings = [];

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        setState(() {
          _timeVal = _shimmerController.value;
        });
      });
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.situationText != null) {
      _soundService.playTts(quest.situationText!);
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered || _scrubProgress < 0.95) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _spokenText = "Calibrating conversational context decoder...";
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
  }

  void _stopSpeechListening() async {
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifyResponseSpoken();
  }

  void _verifyResponseSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Calibrating")) {
      setState(() {
        _spokenText = "No voice frequency signature detected.";
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // Semantic evaluation: does the transcribed speech contain ANY of the accepted key substrings?
    bool matchFound = false;

    for (var sub in _acceptedSubstrings) {
      final String cleanSub = sub.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      if (cleanSpeech.contains(cleanSub)) {
        matchFound = true;
        break;
      }
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = matchFound;
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

  void _onScrubUpdate(double delta) {
    if (_isAnswered || _scrubProgress >= 1.0) return;
    setState(() {
      _scrubProgress = (_scrubProgress + delta).clamp(0.0, 1.0);
      if (_scrubProgress > 0) _hapticService.selection();
      if (_scrubProgress >= 1.0) {
        _hapticService.success();
        _soundService.playCorrect();
      }
    });
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
              _scrubProgress = 0.0;
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
            title: 'SITUATIONAL EXPERT!',
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
          _acceptedSubstrings = quest.acceptedSynonyms ?? [];
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

                      // Frosted Condensation Scrubber Card
                      _buildFogScrubberPanel(quest, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Live Speech Feed Telemetry
                      if (_spokenText.isNotEmpty) ...[
                        _buildFrequencyTelemetryCard(isDark),
                        SizedBox(height: 20.h),
                      ],

                      // Explanation block
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 30.h),

                      // Interactive mic button
                      if (!_isAnswered)
                        _buildScrubbedMicTrigger(theme.primaryColor, isDark),
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
          Icon(Icons.cleaning_services_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 8.w),
          Text(
            "FROSTED CONDENSATION SCRUBBER",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFogScrubberPanel(SpeakingQuest quest, Color primaryColor, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: 1.sw,
        height: 200.h,
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
            // Underlying Revealed Reality Scene Card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1B1B33), const Color(0xFF0F0F1D)]
                        : [Colors.cyan.shade50.withValues(alpha: 0.15), Colors.white],
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
                          "THE SOCIAL SCENE",
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10.sp,
                            color: primaryColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                        ScaleButton(
                          onTap: () => _soundService.playTts(quest.situationText ?? ""),
                          child: Icon(Icons.volume_up_rounded, color: primaryColor, size: 18.r),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      quest.situationText ?? "Situation description.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // Tactile Condensing Fog Overlay
            if (_scrubProgress < 0.98)
              Positioned.fill(
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onScrubUpdate(details.primaryDelta! / 260.w),
                  child: CustomPaint(
                    painter: FogPainter(
                      progress: _scrubProgress,
                      time: _timeVal,
                    ),
                  ),
                ),
              ),

            // Scrub Instructions Overlay
            if (_scrubProgress == 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swipe_rounded, color: Colors.cyanAccent, size: 30.r)
                              .animate(onPlay: (c) => c.repeat())
                              .shake(hz: 2, curve: Curves.easeInOut)
                              .then()
                              .fadeOut(),
                          SizedBox(height: 8.h),
                          Text(
                            "SWIPE TO WIPE CONDENSATION",
                            style: GoogleFonts.shareTechMono(
                              fontSize: 10.sp,
                              color: isDark ? Colors.black54 : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyTelemetryCard(bool isDark) {
    final bool hasInput = _spokenText != "Calibrating conversational context decoder..." && _spokenText != "No voice frequency signature detected.";

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
                color: Colors.cyanAccent,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "DECODED VOICE SIGNATURE",
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
    final Color cardColor = (_isCorrect ?? false) ? Colors.cyanAccent : Colors.redAccent;

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
                (_isCorrect ?? false) ? "Response Decoded!" : "Semantic Decode Failed",
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
            quest.explanation ?? "Responding politely to daily situational constraints forms the bedrock of real native fluency.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
          if (_isCorrect != null && quest.sampleAnswer != null) ...[
            SizedBox(height: 14.h),
            Text(
              "NATIVE SAMPLE REPLY:",
              style: GoogleFonts.shareTechMono(
                fontSize: 10.sp,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              quest.sampleAnswer!,
              style: GoogleFonts.fredoka(
                fontSize: 14.sp,
                color: Colors.cyanAccent,
              ),
            ),
          ]
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildScrubbedMicTrigger(Color primaryColor, bool isDark) {
    final bool isEnabled = _scrubProgress >= 0.95;

    return GestureDetector(
      onLongPressStart: (_) => isEnabled ? _startSpeechListening() : null,
      onLongPressEnd: (_) => isEnabled ? _stopSpeechListening() : null,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Beautiful condensation ring pulses
              if (_isListening)
                ...List.generate(4, (i) {
                  return Container(
                    width: 76.r + (i * 24.r),
                    height: 76.r + (i * 24.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        width: 1.5.r,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15), duration: 800.ms, curve: Curves.easeOut)
                  .fadeOut();
                }),

              // Outer boundary ring
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: isEnabled
                        ? (_isListening
                            ? Colors.cyanAccent.withValues(alpha: 0.35)
                            : primaryColor.withValues(alpha: 0.15))
                        : Colors.grey.withValues(alpha: 0.1),
                    width: 4.r,
                  ),
                ),
              ).animate(target: _isListening ? 1 : 0).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.18, 1.18),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  ),

              // Interactive Mic Core
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isEnabled
                          ? (_isListening
                              ? [Colors.teal[900]!, Colors.cyanAccent]
                              : [const Color(0xFF1F1C2C), const Color(0xFF928DAB)])
                          : [Colors.grey[800]!, Colors.grey[900]!],
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.45),
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
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            !isEnabled
                ? "WIPE SCREEN TO UNLOCK VOCAL PORT"
                : (_isListening
                    ? "RELEASE MICROPHONE TO SUBMIT ANSWER"
                    : "HOLD MICROPHONE TO RESPOND TO SCENE"),
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
