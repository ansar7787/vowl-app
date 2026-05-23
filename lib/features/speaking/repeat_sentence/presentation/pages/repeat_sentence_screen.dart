import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
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

// Sound Wave Tracing custom painter representing vocal alignment
class VisualTracePainter extends CustomPainter {
  final double progress;
  final bool isListening;
  final Color themeColor;
  final List<double> amplitudes;

  VisualTracePainter({
    required this.progress,
    required this.isListening,
    required this.themeColor,
    required this.amplitudes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double width = size.width;

    // 1. Draw static background soundwave guide
    final Paint guidePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.1)
      ..strokeWidth = 2.w
      ..style = PaintingStyle.stroke;

    final Path guidePath = Path();
    guidePath.moveTo(0, midY);

    final int points = 60;
    for (int i = 0; i <= points; i++) {
      final double x = (width / points) * i;
      final double amp = amplitudes.length > i ? amplitudes[i] : 16.0;
      final double y = midY + math.sin(i * 0.3) * amp;
      guidePath.lineTo(x, y);
    }
    canvas.drawPath(guidePath, guidePaint);

    // 2. Draw live active glowing vocal trace path
    if (progress > 0) {
      final Paint activePaint = Paint()
        ..color = themeColor
        ..strokeWidth = 4.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final Paint corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path activePath = Path();
      activePath.moveTo(0, midY);

      final double currentLimitX = width * progress;
      for (double x = 0; x <= currentLimitX; x += 2.w) {
        final double ratio = x / width;
        final int index = (ratio * points).floor();
        final double amp = amplitudes.length > index ? amplitudes[index] : 16.0;
        
        // Add random microphone flutter while recording
        final double flutter = isListening ? (math.sin(x * 0.1 + DateTime.now().millisecondsSinceEpoch * 0.05) * 4.h) : 0;
        final double y = midY + math.sin(ratio * points * 0.3) * (amp + flutter);
        activePath.lineTo(x, y);
      }

      canvas.drawPath(activePath, activePaint);
      canvas.drawPath(activePath, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VisualTracePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.amplitudes != amplitudes;
  }
}

class RepeatSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const RepeatSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.repeatSentence,
  });

  @override
  State<RepeatSentenceScreen> createState() => _RepeatSentenceScreenState();
}

class _RepeatSentenceScreenState extends State<RepeatSentenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();
  
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;
  String _spokenText = "";
  double _progress = 0.0; // Vocal trace tracing progress (0.0 to 1.0)
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  // Pre-cached dynamic target amplitudes for soundwave guidelines
  final List<double> _waveAmplitudes = [];

  @override
  void initState() {
    super.initState();
    _generateSoundwaveGuide();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _generateSoundwaveGuide() {
    final math.Random random = math.Random(widget.level);
    _waveAmplitudes.clear();
    for (int i = 0; i <= 65; i++) {
      // Dynamic height profiles mimicking phoneme sound pressure spikes
      _waveAmplitudes.add(10.h + random.nextDouble() * 24.h);
    }
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered) return;
    _hapticService.selection();
    
    setState(() {
      _isListening = true;
      _spokenText = "Deciphering vocal coordinates...";
      _progress = 0.05;
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
          // Progress tracks similarity length comparison
          _progress = (text.length / 32.0).clamp(0.05, 1.0);
        });
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  void _stopSpeechListening(String expectedAnswer) async {
    await _speechService.stop();
    setState(() => _isListening = false);
    _verifySpeech(expectedAnswer);
  }

  void _verifySpeech(String expected) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Deciphering")) {
      setState(() {
        _spokenText = "No audible vocal input recorded.";
        _progress = 0.0;
      });
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final String cleanExpected = expected.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // Similarity calculations: word-level matching
    final List<String> speechWords = cleanSpeech.split(' ');
    final List<String> expectedWords = cleanExpected.split(' ');

    int matches = 0;
    for (var word in speechWords) {
      if (expectedWords.contains(word)) {
        matches++;
      }
    }

    final double similarity = expectedWords.isNotEmpty ? matches / expectedWords.length : 0.0;
    final bool isCorrect = similarity >= 0.70; // 70% matching word-level accuracy to pass repeat sentence

    setState(() {
      _progress = 1.0;
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
              _isListening = false;
              _progress = 0.0;
              _spokenText = "";
              _generateSoundwaveGuide();
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
            title: 'SOUND WAVE TRANSCRIBER!',
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
                      
                      // Sound audition box card
                      _buildAuditionCard(quest, theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Soundwave spectrum visualizer
                      _buildWaveChamber(theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Speech telemetry output box
                      _buildTelemetryCard(isDark),
                      SizedBox(height: 30.h),

                      // Tactile recording button
                      if (!_isAnswered)
                        _buildTactileMic(quest.correctAnswer ?? "", theme.primaryColor),

                      // Review explanations
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
              Icon(Icons.graphic_eq_rounded, size: 12.r, color: primaryColor),
              SizedBox(width: 8.w),
              Text(
                "HOLD TO TRACE SOUND WAVE",
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
          "Listen to the target phrase and repeat it exactly to align the wave cores!",
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

  Widget _buildAuditionCard(GameQuest quest, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(22.r),
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TARGET STATEMENT TO REPEAT",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: primaryColor,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ScaleButton(
                onTap: () => _soundService.playTts(quest.textToSpeak ?? ""),
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
                        "LISTEN",
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
            quest.correctAnswer ?? "",
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 20.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveChamber(Color primaryColor, bool isDark) {
    return Container(
      width: 1.sw,
      height: 140.h,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: CustomPaint(
        painter: VisualTracePainter(
          progress: _progress,
          isListening: _isListening,
          themeColor: primaryColor,
          amplitudes: _waveAmplitudes,
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
            "LIVE SPEECH TELEMETRY OUTPUT",
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

  Widget _buildTactileMic(String correctAnswer, Color primaryColor) {
    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => _startSpeechListening(),
          onLongPressEnd: (_) => _stopSpeechListening(correctAnswer),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isListening)
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
                      colors: _isListening
                          ? [primaryColor, primaryColor.withValues(alpha: 0.7)]
                          : [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 18,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
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
          _isListening ? "RELEASE LENS TO PROCESS PHONEMES" : "HOLD LENS TO RECORD YOUR SPEECH",
          style: GoogleFonts.shareTechMono(
            fontSize: 9.sp,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationCard(GameQuest quest, bool isDark) {
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
                (_isCorrect ?? false) ? "Wave Aligned Perfectly!" : "Wave Mismatch Identified!",
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
            quest.explanation ?? "Matching vocal amplitudes and phonetic structures correctly builds speech confidence.",
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
