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

// Thermal Grid Painter that visualizes energy ripple lines that heat up or cool down based on voice input
class ThermalGridPainter extends CustomPainter {
  final double heatLevel;
  final bool isListening;
  final double time;

  ThermalGridPainter({
    required this.heatLevel,
    required this.isListening,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final int rows = 12;
    final int cols = 12;

    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Calculate center of each cell
        final double cx = c * cellWidth + cellWidth / 2;
        final double cy = r * cellHeight + cellHeight / 2;

        // Grid distance from center
        final double dx = cx - size.width / 2;
        final double dy = cy - size.height / 2;
        final double distance = math.sqrt(dx * dx + dy * dy);

        // Ripple wave calculation using sine curves
        final double wave = math.sin((distance / 20.0) - (time * 5.0)) * 0.5 + 0.5;

        // Interpolate grid cell sizes and colors
        final double baseSize = 4.0.r;
        final double activeMultiplier = isListening ? (3.0 + wave * 5.0) * (0.3 + heatLevel * 0.7) : 1.0;
        final double finalSize = baseSize * activeMultiplier;

        // Sizzle heat colors: cold cobalt blue -> superheated thermodynamic orange
        final Color coldColor = const Color(0xFF1D2671).withValues(alpha: 0.2);
        final Color hotColor = const Color(0xFFFF5722).withValues(alpha: 0.95);
        final Color activeColor = Color.lerp(coldColor, hotColor, heatLevel * 0.8 + wave * 0.2)!;

        paint.color = activeColor;
        canvas.drawCircle(Offset(cx, cy), finalSize, paint);

        // Draw faint glowing border for highly active cells
        if (isListening && heatLevel > 0.6) {
          final Paint glowPaint = Paint()
            ..color = hotColor.withValues(alpha: 0.15 * wave)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0.r;
          canvas.drawCircle(Offset(cx, cy), finalSize + 4.0.r, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ThermalGridPainter oldDelegate) {
    return oldDelegate.heatLevel != heatLevel ||
        oldDelegate.isListening != isListening ||
        oldDelegate.time != time;
  }
}

class PronunciationFocusScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const PronunciationFocusScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pronunciationFocus,
  });

  @override
  State<PronunciationFocusScreen> createState() => _PronunciationFocusScreenState();
}

class _PronunciationFocusScreenState extends State<PronunciationFocusScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  double _heatLevel = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  // Real-time animation components
  late AnimationController _tickerController;
  Timer? _heatTimer;
  double _timeVal = 0.0;
  String _spokenText = "";
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    // Fast-ticking controller to update the glowing soundwave custom painters
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          _timeVal = _tickerController.value;
        });
      });
    _tickerController.repeat();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _heatTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  void _startListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _heatLevel = 0.05;
      _spokenText = "Calibrating mouth audio streams...";
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

    // Dynamic timer that makes the heat rise and swell based on voice presence
    _heatTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      setState(() {
        // Voice amplitude swells up to 1.0 slowly
        if (_heatLevel < 0.95) {
          _heatLevel += 0.015 + (math.Random().nextDouble() * 0.01);
        } else {
          _heatLevel = 0.95 + (math.Random().nextDouble() * 0.05); // Vibration noise
        }
      });
    });
  }

  void _stopListening(String expectedText) async {
    _heatTimer?.cancel();
    await _speechService.stop();
    
    setState(() {
      _isListening = false;
    });

    _verifyPronunciation(expectedText);
  }

  void _verifyPronunciation(String expected) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Calibrating")) {
      setState(() {
        _spokenText = "No audible voice input recorded.";
        _heatLevel = 0.0;
      });
      _hapticService.error();
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
    final bool passed = similarity >= 0.75; // Strict 75% phonetic match to achieve critical mass fusion

    setState(() {
      _isAnswered = true;
      _isCorrect = passed;
      _heatLevel = passed ? 1.0 : 0.0;
    });

    if (passed) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(SubmitAnswer(false));
    }
  }

  // Highlight words in the sentence that contain the phonetic letters of the target sound
  List<Widget> _buildHighlightedSentence(String text, String targetPhoneme, Color primaryColor, bool isDark) {
    final words = text.split(' ');
    final String phonemeChar = targetPhoneme.replaceAll('[', '').replaceAll(']', '').toLowerCase();

    return words.map((word) {
      final String cleanWord = word.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      final bool hasPhoneme = cleanWord.contains(phonemeChar) && phonemeChar.isNotEmpty;

      return GestureDetector(
        onTap: () => _soundService.playTts(word),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: hasPhoneme
                ? (isDark ? Colors.orange[900]!.withValues(alpha: 0.25) : Colors.orange[100]!)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: hasPhoneme
                  ? Colors.orangeAccent.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: hasPhoneme
                ? [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      blurRadius: 6,
                    )
                  ]
                : [],
          ),
          child: Text(
            word,
            style: GoogleFonts.fredoka(
              fontSize: 18.sp,
              fontWeight: hasPhoneme ? FontWeight.bold : FontWeight.w500,
              color: hasPhoneme
                  ? Colors.orangeAccent
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      );
    }).toList();
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
              _heatLevel = 0.0;
              _spokenText = "";
              _showGuide = false;
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
            title: 'CRITICAL MASS FUSION!',
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
                      _buildHeaderPill(theme.primaryColor),
                      SizedBox(height: 12.h),

                      // Glassmorphic Floating Crucible Capsule
                      _buildPhonemeCrucible(quest, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Interactive Thermal Grid Soundwave Panel
                      _buildThermalGridPanel(isDark),
                      SizedBox(height: 20.h),

                      // Word-by-word highlighted sentence
                      _buildHighlightedSentenceCard(quest, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Real-time spoken text box feedback
                      if (_spokenText.isNotEmpty) ...[
                        _buildTelemetryCard(isDark),
                        SizedBox(height: 24.h),
                      ],

                      // Explanations reviewer
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 30.h),

                      // Sizzling Mic lens trigger
                      if (!_isAnswered)
                        _buildMicCoreButton(quest.textToSpeak ?? "", theme.primaryColor, isDark),
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
          Icon(Icons.whatshot_rounded, size: 14.r, color: Colors.orangeAccent),
          SizedBox(width: 8.w),
          Text(
            "THERMOGRAPHIC ACCENT CALIBRATOR",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonemeCrucible(SpeakingQuest quest, Color primaryColor, bool isDark) {
    final String targetSound = quest.targetPhoneme ?? "[r]";

    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(28.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TARGET PHONETIC CORE",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.0,
                ),
              ),
              ScaleButton(
                onTap: () {
                  _hapticService.selection();
                  setState(() => _showGuide = !_showGuide);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.help_outline_rounded, color: Colors.orangeAccent, size: 12.r),
                      SizedBox(width: 4.w),
                      Text(
                        "POSITION GUIDE",
                        style: GoogleFonts.shareTechMono(
                          fontSize: 9.sp,
                          color: Colors.orangeAccent,
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
          
          // Glowing liquid metal sphere capsule
          Container(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(const Color(0xFF1F1C2C), const Color(0xFFFF512F), _heatLevel)!,
                  Color.lerp(const Color(0xFF928DAB), const Color(0xFFDD2476), _heatLevel)!,
                ],
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(Colors.blue, Colors.orangeAccent, _heatLevel)!
                      .withValues(alpha: 0.35 + _heatLevel * 0.25),
                  blurRadius: 15.r + _heatLevel * 10.r,
                ),
              ],
            ),
            child: Text(
              targetSound,
              style: GoogleFonts.fredoka(
                fontSize: 32.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: -0.05, end: 0.05, duration: 1.5.seconds),

          AnimatedCrossFade(
            firstChild: const SizedBox(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Column(
                children: [
                  const Divider(color: Colors.white12),
                  SizedBox(height: 8.h),
                  Text(
                    quest.phoneticHint ?? "Accentuate the critical sound matching the crucible target.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _showGuide ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalGridPanel(bool isDark) {
    return Container(
      width: 1.sw,
      height: 120.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C16) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: CustomPaint(
          painter: ThermalGridPainter(
            heatLevel: _heatLevel,
            isListening: _isListening,
            time: _timeVal,
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedSentenceCard(SpeakingQuest quest, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(22.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "HEATMAP SENTENCE (TAP TO LISTEN)",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey,
                ),
              ),
              ScaleButton(
                onTap: () => _soundService.playTts(quest.textToSpeak ?? ""),
                child: Icon(Icons.volume_up_rounded, color: primaryColor, size: 18.r),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4.w,
            runSpacing: 4.h,
            children: _buildHighlightedSentence(
              quest.textToSpeak ?? "",
              quest.targetPhoneme ?? "",
              primaryColor,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(bool isDark) {
    final bool hasValidVoice = _spokenText != "Calibrating mouth audio streams..." && _spokenText != "No audible voice input recorded.";

    return GlassTile(
      padding: EdgeInsets.all(18.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hasValidVoice ? Icons.graphic_eq_rounded : Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "DECODED PHONETIC SPEECH",
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
                (_isCorrect ?? false) ? "Critical Mass Achieved!" : "Phonetic Synthesis Failed",
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
            quest.explanation ?? "Correlating target accent placements with physical vocal mechanics accelerates proper sentence stress.",
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

  Widget _buildMicCoreButton(String textToSpeak, Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _startListening(),
      onLongPressEnd: (_) => _stopListening(textToSpeak),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer thermo glow aura ring
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: _isListening
                        ? Colors.orangeAccent.withValues(alpha: 0.3)
                        : Colors.blueAccent.withValues(alpha: 0.1),
                    width: 4.r,
                  ),
                ),
              ).animate(target: _isListening ? 1 : 0).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.15, 1.15),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  ),
              
              // Inner sizzling button core
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [Colors.orange[900]!, Colors.orangeAccent]
                          : [const Color(0xFF0F2027), const Color(0xFF203A43)],
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: Colors.orangeAccent.withValues(alpha: 0.45),
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
                    _isListening ? Icons.local_fire_department_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _isListening ? "RELEASE CORE TO INITIATE FUSION" : "HOLD SIZZLE CORE TO RECORD PHONEME ACCENT",
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
