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

// Highly interactive Bloom Painter representing a glowing holographic flora that expands and blossoms under vocal water
class BloomPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final bool isListening;
  final double time;

  BloomPainter({
    required this.progress,
    required this.primaryColor,
    required this.isListening,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double stemHeight = 40.h;

    // Draw holographic glowing stem
    final Paint stemPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.3 + progress * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.r
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(center.dx, size.height)
      ..quadraticBezierTo(
        center.dx + math.sin(time * 3.0) * 10 * progress,
        size.height - stemHeight,
        center.dx,
        center.dy + 15.r,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Glowing base leaves
    final Paint leafPaint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.2 + progress * 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - 20.w, size.height - 20.h),
        width: 25.w * (0.5 + progress * 0.5),
        height: 12.h,
      ),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 20.w, size.height - 20.h),
        width: 25.w * (0.5 + progress * 0.5),
        height: 12.h,
      ),
      leafPaint,
    );

    // Draw glowing petals
    final int numPetals = 8;
    final Paint petalPaint = Paint()..style = PaintingStyle.fill;
    final Paint glowPaint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.r);

    for (int i = 0; i < numPetals; i++) {
      // Angular spacing
      final double angle = (i * math.pi * 2) / numPetals + (time * 0.1);
      final double petalDist = 38.r * progress;
      final double petalSize = (14.r + math.sin(time * 4.0 + i) * 2.r) * (0.4 + progress * 0.6);

      // Color mapping: sleep indigo -> radiant pink-violet bloom
      final Color sleepColor = primaryColor.withValues(alpha: 0.25);
      final Color activeColor = Color.lerp(
        sleepColor,
        const Color(0xFFDD2476),
        progress,
      )!;

      final Offset petalCenter = Offset(
        center.dx + math.cos(angle) * petalDist,
        center.dy + math.sin(angle) * petalDist,
      );

      // Draw petal aura glow
      glowPaint.color = activeColor.withValues(alpha: 0.3 * progress);
      canvas.drawCircle(petalCenter, petalSize + 6.r, glowPaint);

      // Draw solid petal
      petalPaint.color = activeColor;
      canvas.drawCircle(petalCenter, petalSize, petalPaint);

      // Draw internal petal ribbing
      final Paint linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.r;
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle) * (petalDist + petalSize * 0.6),
          center.dy + math.sin(angle) * (petalDist + petalSize * 0.6),
        ),
        linePaint,
      );
    }

    // Glowing core seed
    final Paint corePaint = Paint()
      ..color = Color.lerp(Colors.orangeAccent, Colors.yellowAccent, progress)!
      ..style = PaintingStyle.fill;
    final double coreRadius = (12.r + math.sin(time * 5.0) * 1.r) * (0.8 + progress * 0.4);

    // Core Glow
    final Paint coreGlow = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.r);
    canvas.drawCircle(center, coreRadius + 5.r, coreGlow);
    canvas.drawCircle(center, coreRadius, corePaint);
  }

  @override
  bool shouldRepaint(covariant BloomPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.time != time;
  }
}

class SpeakSynonymScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SpeakSynonymScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakSynonym,
  });

  @override
  State<SpeakSynonymScreen> createState() => _SpeakSynonymScreenState();
}

class _SpeakSynonymScreenState extends State<SpeakSynonymScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  double _bloomProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  // Animation controller for leaf swaying and core particle pulsation
  late AnimationController _swingController;
  Timer? _bloomTimer;
  double _timeVal = 0.0;
  String _spokenText = "";
  List<String> _acceptedSyns = [];

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
        setState(() {
          _timeVal = _swingController.value;
        });
      });
    _swingController.repeat();
  }

  @override
  void dispose() {
    _swingController.dispose();
    _bloomTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      // Strip asterisks for TTS playback
      final String cleanSentence = quest.textToSpeak!.replaceAll('*', '');
      _soundService.playTts(cleanSentence);
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _bloomProgress = 0.08;
      _spokenText = "Gathering floral audio signals...";
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

    // Gradually swell floral progress to simulate active watering / speech feedback
    _bloomTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_bloomProgress < 0.90) {
          _bloomProgress += 0.012 + (math.Random().nextDouble() * 0.008);
        } else {
          _bloomProgress = 0.90 + (math.Random().nextDouble() * 0.04);
        }
      });
    });
  }

  void _stopSpeechListening() async {
    _bloomTimer?.cancel();
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifySynonymSpoken();
  }

  void _verifySynonymSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Gathering")) {
      setState(() {
        _spokenText = "No audible voice input recorded.";
        _bloomProgress = 0.0;
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final List<String> speechWords = cleanSpeech.split(' ');

    // Match checks: did they speak ANY of the accepted synonyms?
    bool matchFound = false;

    for (var word in speechWords) {
      final String cleanWord = word.trim().replaceAll(RegExp(r'[^\w]'), '');
      for (var syn in _acceptedSyns) {
        final String cleanSyn = syn.trim().toLowerCase();
        if (cleanWord == cleanSyn || cleanWord.contains(cleanSyn) || cleanSyn.contains(cleanWord)) {
          matchFound = true;
          break;
        }
      }
      if (matchFound) break;
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = matchFound;
      _bloomProgress = matchFound ? 1.0 : 0.0;
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

  void _extractTargetWord(String text, List<String> synonyms) {
    _acceptedSyns = synonyms;
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
              _bloomProgress = 0.0;
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
            title: 'LEXICAL PIVOT COMPLETE!',
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
          _extractTargetWord(quest.textToSpeak ?? "", quest.acceptedSynonyms ?? []);
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
                      SizedBox(height: 12.h),

                      // Sentence block displaying text with styled neon seed core
                      _buildSentencePanel(quest, theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Holographic Blooming Garden canvas
                      _buildGardenPanel(theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Telemetry decoded voice feedback
                      if (_spokenText.isNotEmpty) ...[
                        _buildTelemetryCard(isDark),
                        SizedBox(height: 20.h),
                      ],

                      // Explanations drawer
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 30.h),

                      // Audio capturing trigger
                      if (!_isAnswered)
                        _buildWateringMicTrigger(theme.primaryColor, isDark),
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
          Icon(Icons.eco_rounded, size: 14.r, color: Colors.greenAccent),
          SizedBox(width: 8.w),
          Text(
            "LEXICAL SYNONYM SEED",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentencePanel(SpeakingQuest quest, Color primaryColor, bool isDark) {
    final String fullText = quest.textToSpeak ?? "";
    final List<String> segments = fullText.split('*');

    return GlassTile(
      padding: EdgeInsets.all(22.r),
      borderRadius: BorderRadius.circular(26.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SUBSTITUTE HIGHLIGHTED SEED",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.0,
                ),
              ),
              ScaleButton(
                onTap: () => _soundService.playTts(fullText.replaceAll('*', '')),
                child: Icon(Icons.volume_up_rounded, color: primaryColor, size: 18.r),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.fredoka(
                fontSize: 18.sp,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
              children: segments.asMap().entries.map((e) {
                final bool isTarget = e.key % 2 != 0;
                if (isTarget) {
                  return WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => _soundService.playTts(e.value),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 1.5.w),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.1),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Text(
                          e.value,
                          style: GoogleFonts.fredoka(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return TextSpan(text: e.value);
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenPanel(Color primaryColor, bool isDark) {
    return Container(
      width: 1.sw,
      height: 180.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C16) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.r,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Stack(
          children: [
            // Glowing background aura
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isListening ? 0.35 : 0.05,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [primaryColor, Colors.transparent],
                      radius: 0.7,
                    ),
                  ),
                ),
              ),
            ),
            
            // Central blooming CustomPaint
            Positioned.fill(
              child: CustomPaint(
                painter: BloomPainter(
                  progress: _bloomProgress,
                  primaryColor: primaryColor,
                  isListening: _isListening,
                  time: _timeVal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryCard(bool isDark) {
    final bool hasInput = _spokenText != "Gathering floral audio signals..." && _spokenText != "No audible voice input recorded.";

    return GlassTile(
      padding: EdgeInsets.all(18.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hasInput ? Icons.graphic_eq_rounded : Icons.warning_amber_rounded,
                color: Colors.greenAccent,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "CAPTURED LEXICAL RESPONSE",
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
                (_isCorrect ?? false) ? "Seed Bloomed Perfectly!" : "Seed Core Remained Dormant",
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
            quest.explanation ?? "Associating and identifying strong contextual synonyms broadens mental lexicon flexibility.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
          if (!(_isCorrect ?? false) && _acceptedSyns.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Text(
              "ACCEPTED SYNONYMS:",
              style: GoogleFonts.shareTechMono(
                fontSize: 10.sp,
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: _acceptedSyns.map((s) => Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.25)),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.fredoka(
                    fontSize: 12.sp,
                    color: Colors.orangeAccent,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildWateringMicTrigger(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _startSpeechListening(),
      onLongPressEnd: (_) => _stopSpeechListening(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Beautiful glowing water droplet streams floating up while recording is active
              if (_isListening)
                ...List.generate(6, (i) {
                  final double shiftX = -30.w + (i * 12.w) + (math.sin(_timeVal * 10.0 + i) * 4.w);
                  return Positioned(
                    bottom: 50.h,
                    left: 1.sw / 2 + shiftX,
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: Colors.cyanAccent.withValues(alpha: 0.7),
                      size: (12.r + i * 2.r).clamp(10, 24).toDouble(),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(begin: 0, end: -120.h, duration: (600 + i * 150).ms, curve: Curves.easeOut)
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
                        ? Colors.greenAccent.withValues(alpha: 0.3)
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
                          ? [Colors.teal[800]!, Colors.greenAccent]
                          : [const Color(0xFF0F2027), const Color(0xFF203A43)],
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.45),
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
                    _isListening ? Icons.opacity_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _isListening ? "RELEASE CORE TO STOP WATERING" : "HOLD CAN TO WATER WITH A SPOKEN SYNONYM",
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
