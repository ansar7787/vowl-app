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

// Tension track custom painter that bends dynamically based on slider displacement
class TrackPainter extends CustomPainter {
  final double tiltValue; // -1.0 to 1.0
  final Color themeColor;

  TrackPainter({required this.tiltValue, required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double width = size.width;

    final Paint trackPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 4.h
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint activePaint = Paint()
      ..color = tiltValue < 0 ? Colors.redAccent : Colors.greenAccent
      ..strokeWidth = 5.h
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final Path path = Path();
    path.moveTo(0, midY);

    // Apply tension deflection curve (sine)
    final double centerX = width / 2;
    final double sphereX = centerX + (tiltValue * (width / 2 - 40.w));
    
    for (double x = 0; x <= width; x += 4.w) {
      final double distanceToSphere = (x - sphereX).abs();
      final double deflection = math.max(0.0, 1.0 - (distanceToSphere / 60.w));
      
      // Bend downwards up to 12.h
      final double y = midY + (math.sin(deflection * math.pi / 2) * 12.h * tiltValue.abs());
      path.lineTo(x, y);
    }

    canvas.drawPath(path, trackPaint);

    if (tiltValue != 0) {
      final Path activePath = Path();
      activePath.moveTo(centerX, midY);
      
      final double start = math.min(centerX, sphereX);
      final double end = math.max(centerX, sphereX);
      
      for (double x = start; x <= end; x += 4.w) {
        final double distanceToSphere = (x - sphereX).abs();
        final double deflection = math.max(0.0, 1.0 - (distanceToSphere / 60.w));
        final double y = midY + (math.sin(deflection * math.pi / 2) * 12.h * tiltValue.abs());
        activePath.lineTo(x, y);
      }
      canvas.drawPath(activePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TrackPainter oldDelegate) {
    return oldDelegate.tiltValue != tiltValue || oldDelegate.themeColor != themeColor;
  }
}

class YesNoSpeakingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const YesNoSpeakingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.yesNoSpeaking,
  });

  @override
  State<YesNoSpeakingScreen> createState() => _YesNoSpeakingScreenState();
}

class _YesNoSpeakingScreenState extends State<YesNoSpeakingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;

  double _tiltValue = 0.0; // -1.0 (No) to 1.0 (Yes)
  bool _isSnapped = false;
  bool _isSpeechActive = false;

  // Telemetry details
  String _spokenText = "";
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.prompt != null) {
      _soundService.playTts(quest.prompt!);
    }
  }

  void _onTiltDragged(DragUpdateDetails details, double trackWidth) {
    if (_isAnswered || _isSnapped) return;
    
    // Normalized displacement relative to half-track limits
    final double deltaNormalized = details.delta.dx / (trackWidth / 2);
    _hapticService.selection();

    setState(() {
      _tiltValue = (_tiltValue + deltaNormalized).clamp(-1.0, 1.0);
      
      // Auto snap to boundary gates past 85%
      if (_tiltValue <= -0.85) {
        _tiltValue = -1.0;
        _isSnapped = true;
        _soundService.playClick();
        _hapticService.selection();
      } else if (_tiltValue >= 0.85) {
        _tiltValue = 1.0;
        _isSnapped = true;
        _soundService.playClick();
        _hapticService.selection();
      }
    });
  }

  void _startSpeechListening() async {
    if (_isAnswered || !_isSnapped) return;
    _hapticService.selection();

    setState(() {
      _isSpeechActive = true;
      _spokenText = "Voice capturing initiated...";
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isSpeechActive = false);
      },
    );
  }

  void _stopSpeechListening(String expectedText, bool expectedMatch) async {
    await _speechService.stop();
    setState(() => _isSpeechActive = false);
    _verifyBinaryResponse(expectedText, expectedMatch);
  }

  void _verifyBinaryResponse(String expectedText, bool expectedMatch) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Voice capturing")) {
      setState(() {
        _spokenText = "No audible voice input recorded.";
      });
      return;
    }

    // 1. Evaluate binary slide accuracy
    final bool chosenMatch = _tiltValue > 0;
    final bool binaryIsCorrect = chosenMatch == expectedMatch;

    // 2. Evaluate phonetic reading accuracy of target sampleAnswer
    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final String cleanExpected = expectedText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    final List<String> speechWords = cleanSpeech.split(' ');
    final List<String> expectedWords = cleanExpected.split(' ');

    int matches = 0;
    for (var word in speechWords) {
      if (expectedWords.contains(word)) {
        matches++;
      }
    }

    final double similarity = expectedWords.isNotEmpty ? matches / expectedWords.length : 0.0;
    final bool speechIsCorrect = similarity >= 0.70;

    final bool isCorrect = binaryIsCorrect && speechIsCorrect;

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
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
              _isSnapped = false;
              _tiltValue = 0.0;
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
            title: 'BINARY RESPONDER!',
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

        // Binary check: do the written sampleAnswer and target prompt match exactly?
        final String rawPrompt = quest?.prompt ?? "";
        final String rawSample = quest?.sampleAnswer ?? "";
        
        final bool doTheyMatch = rawPrompt.trim().toLowerCase() == rawSample.trim().toLowerCase();

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
                      _buildHeaderInstruction(theme.primaryColor),
                      SizedBox(height: 16.h),

                      // Audition card displaying target comparison text
                      _buildAuditionCard(quest, theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Neon Bending Tension slider track arena
                      _buildTiltArena(theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Speech telemetry output box
                      if (_isSnapped) ...[
                        _buildTelemetryCard(isDark),
                        SizedBox(height: 30.h),

                        if (!_isAnswered)
                          _buildTactileMic(quest.sampleAnswer ?? "", doTheyMatch, theme.primaryColor),
                      ],

                      // Explanation cards review
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderInstruction(Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edgesensor_high_rounded, size: 12.r, color: primaryColor),
              SizedBox(width: 8.w),
              Text(
                _isSnapped ? "NOW SPEAK THE TARGET SENTENCE" : "TILT THE CORE SPHERE TO ALIGN",
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          _isSnapped
              ? "Alignment locked! Hold the recording lens and read the target sentence aloud!"
              : "Compare the spoken audio prompt with the written card below and slide to YES or NO!",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildAuditionCard(SpeakingQuest quest, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(22.r),
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "COMPARE PHRASE STRUCTURES",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: primaryColor,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ScaleButton(
                onTap: () => _soundService.playTts(quest.prompt ?? ""),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.volume_up_rounded, color: primaryColor, size: 16.r),
                      SizedBox(width: 6.w),
                      Text(
                        "REPLAY AUDIO",
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10.sp,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          Text(
            "WRITTEN TARGET CARD:",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            quest.sampleAnswer ?? "",
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 18.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiltArena(Color primaryColor, bool isDark) {
    final double trackWidth = 280.w;

    return Container(
      width: 1.sw,
      height: 150.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Neon dynamic bending tension track custom painter
          Positioned.fill(
            child: CustomPaint(
              painter: TrackPainter(
                tiltValue: _tiltValue,
                themeColor: primaryColor,
              ),
            ),
          ),

          // 2. Boundary gate zones
          Positioned(
            left: 12.w,
            child: _buildGateZone("NO (MISMATCH)", Colors.redAccent, _tiltValue <= -0.85),
          ),
          Positioned(
            right: 12.w,
            child: _buildGateZone("YES (MATCH)", Colors.greenAccent, _tiltValue >= 0.85),
          ),

          // 3. Central dragging glowing sphere
          Positioned(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) => _onTiltDragged(details, trackWidth),
              onHorizontalDragEnd: (_) {
                // Return to center if not snapped
                if (!_isSnapped) {
                  setState(() => _tiltValue = 0.0);
                }
              },
              child: Transform.translate(
                offset: Offset(_tiltValue * (trackWidth / 2 - 40.w), 0),
                child: ScaleButton(
                  onTap: () {},
                  child: Container(
                    width: 66.r,
                    height: 66.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          _tiltValue < 0
                              ? Colors.redAccent
                              : (_tiltValue > 0 ? Colors.greenAccent : primaryColor),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_tiltValue < 0
                                  ? Colors.redAccent
                                  : (_tiltValue > 0 ? Colors.greenAccent : primaryColor))
                              .withValues(alpha: 0.45),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isSnapped ? Icons.lock_rounded : Icons.blur_on_rounded,
                      color: Colors.white,
                      size: 26.r,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateZone(String label, Color color, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive ? Colors.white24 : color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                )
              ]
            : [],
      ),
      child: Text(
        label,
        style: GoogleFonts.shareTechMono(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : color,
        ),
      ),
    );
  }

  Widget _buildTelemetryCard(bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "VOCAL DECRYPTION OUTPUT",
            style: GoogleFonts.shareTechMono(
              fontSize: 9.sp,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _spokenText.isEmpty ? "Hold record lens and speak target sentence..." : _spokenText,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontStyle: _spokenText.isEmpty ? FontStyle.normal : FontStyle.italic,
              color: _spokenText.isEmpty
                  ? (isDark ? Colors.white30 : Colors.black38)
                  : (isDark ? Colors.white70 : Colors.black87),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTactileMic(String targetText, bool expectedMatch, Color primaryColor) {
    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => _startSpeechListening(),
          onLongPressEnd: (_) => _stopSpeechListening(targetText, expectedMatch),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isSpeechActive)
                ...List.generate(
                  3,
                  (i) => Container(
                    width: 90.r + (i * 24.r),
                    height: 90.r + (i * 24.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.3, 1.3),
                        duration: 1.seconds,
                      ).fadeOut(),
                ),
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isSpeechActive
                          ? [primaryColor, primaryColor.withValues(alpha: 0.7)]
                          : [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                    boxShadow: _isSpeechActive
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 18,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isSpeechActive ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          _isSpeechActive ? "RELEASE LENS TO PROCESS SENTENCE" : "HOLD LENS TO RECORD TARGET SENTENCE",
          textAlign: TextAlign.center,
          style: GoogleFonts.shareTechMono(
            fontSize: 9.sp,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationCard(SpeakingQuest quest, bool isDark) {
    final Color cardColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.orangeAccent;

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
                (_isCorrect ?? false) ? "Binary Alignment Active!" : "Binary Alignment Failed!",
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
            quest.explanation ?? "Correlating binary comparison gates with actual phonetic speaking speeds builds mental syntax agility.",
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
}
