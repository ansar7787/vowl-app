import 'dart:async';
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

// Highly interactive Plasma Arc Painter depicting electromagnetic ripples between positive and negative poles
class PlasmaPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final bool isListening;
  final double time;

  PlasmaPainter({
    required this.progress,
    required this.primaryColor,
    required this.isListening,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw central conduit pathway
    final Paint conduitPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.w
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width / 2, 10.h), Offset(size.width / 2, size.height - 10.h), conduitPaint);

    // Draw charging base poles (Top and Bottom hubs)
    final Paint hubPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.r;

    // Top Positive Hub aura
    hubPaint.color = Colors.redAccent.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(size.width / 2, 10.h), 14.r + math.sin(time * 4) * 2.r, hubPaint);
    hubPaint.color = Colors.redAccent;
    canvas.drawCircle(Offset(size.width / 2, 10.h), 6.r, hubPaint..style = PaintingStyle.fill);

    // Bottom Negative Hub aura
    final Color bottomHubColor = Color.lerp(Colors.cyanAccent.withValues(alpha: 0.3), Colors.cyanAccent, progress)!;
    hubPaint.color = bottomHubColor.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(size.width / 2, size.height - 10.h), 14.r + math.cos(time * 4) * 2.r, hubPaint..style = PaintingStyle.stroke);
    hubPaint.color = bottomHubColor;
    canvas.drawCircle(Offset(size.width / 2, size.height - 10.h), 6.r, hubPaint..style = PaintingStyle.fill);

    // Draw active electromagnetic plasma arcs
    if (progress > 0) {
      final Paint plasmaPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.8)
        ..strokeWidth = 4.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.r);

      final Paint corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path plasmaPath = Path();
      plasmaPath.moveTo(size.width / 2, 10.h);

      // Generate crackling high-voltage displacement steps
      final double totalHeight = size.height - 20.h;
      final double currentHeight = totalHeight * progress;
      final int steps = 14;

      for (int i = 1; i <= steps; i++) {
        final double stepProgress = i / steps;
        if (stepProgress > progress) break;

        final double y = 10.h + totalHeight * stepProgress;
        // Generate high frequency electrical noise
        final double noise = isListening
            ? (math.sin(time * 25.0 + i) * 16.w * math.Random().nextDouble())
            : (math.sin(time * 12.0 + i) * 6.w);

        plasmaPath.lineTo(size.width / 2 + noise, y);
      }

      canvas.drawPath(plasmaPath, plasmaPaint);
      canvas.drawPath(plasmaPath, corePaint);

      // Draw sliding plasma spark capsule
      final Offset sparkCenter = Offset(
        size.width / 2 + (isListening ? math.sin(time * 30) * 4.w : 0),
        10.h + currentHeight,
      );

      final Paint sparkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final Paint sparkGlow = Paint()
        ..color = Colors.cyanAccent
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.r);

      canvas.drawCircle(sparkCenter, 15.r, sparkGlow);
      canvas.drawCircle(sparkCenter, 8.r, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PlasmaPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.time != time;
  }
}

class SpeakOppositeScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SpeakOppositeScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakOpposite,
  });

  @override
  State<SpeakOppositeScreen> createState() => _SpeakOppositeScreenState();
}

class _SpeakOppositeScreenState extends State<SpeakOppositeScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  double _pullProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  // Animation controller for high-voltage plasma crackling oscillation
  late AnimationController _sparkController;
  Timer? _pullTimer;
  double _timeVal = 0.0;
  String _spokenText = "";
  List<String> _acceptedAntonyms = [];

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          _timeVal = _sparkController.value;
        });
      });
    _sparkController.repeat();
  }

  @override
  void dispose() {
    _sparkController.dispose();
    _pullTimer?.cancel();
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
      _pullProgress = 0.05;
      _spokenText = "Calibrating reverse polarization channel...";
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

    // Gradual charging of the plasma bridge
    _pullTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_pullProgress < 0.92) {
          _pullProgress += 0.015 + (math.Random().nextDouble() * 0.008);
        } else {
          _pullProgress = 0.92 + (math.Random().nextDouble() * 0.03);
        }
      });
    });
  }

  void _stopSpeechListening() async {
    _pullTimer?.cancel();
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifyOppositeSpoken();
  }

  void _verifyOppositeSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Calibrating")) {
      setState(() {
        _spokenText = "No magnetic frequency detected.";
        _pullProgress = 0.0;
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final List<String> speechWords = cleanSpeech.split(' ');

    // Match checks: did they speak ANY of the accepted antonyms?
    bool matchFound = false;

    for (var word in speechWords) {
      final String cleanWord = word.trim().replaceAll(RegExp(r'[^\w]'), '');
      for (var ant in _acceptedAntonyms) {
        final String cleanAnt = ant.trim().toLowerCase();
        if (cleanWord == cleanAnt || cleanWord.contains(cleanAnt) || cleanAnt.contains(cleanWord)) {
          matchFound = true;
          break;
        }
      }
      if (matchFound) break;
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = matchFound;
      _pullProgress = matchFound ? 1.0 : 0.0;
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
              _pullProgress = 0.0;
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
            title: 'POLAR ANTIPODE FUSED!',
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
          _acceptedAntonyms = quest.acceptedSynonyms ?? [];
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
                      _buildHeaderPill(),
                      SizedBox(height: 12.h),

                      // Positive Pole Node Sentence Card
                      _buildPositivePolePanel(quest, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Plasma Conduit custom paint
                      _buildPlasmaConduitPanel(theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Negative Pole Node Receiver
                      _buildNegativePolePanel(isDark),
                      SizedBox(height: 20.h),

                      // Decoded frequency voice feedback
                      if (_spokenText.isNotEmpty) ...[
                        _buildFrequencyTelemetryCard(isDark),
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

                      // Electromagnetic mic activator
                      if (!_isAnswered)
                        _buildElectromagneticTrigger(theme.primaryColor, isDark),
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_vertical_circle_rounded, size: 14.r, color: Colors.redAccent),
          SizedBox(width: 8.w),
          Text(
            "POLAR ELECTROMAGNETIC CONDUIT",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositivePolePanel(GameQuest quest, Color primaryColor, bool isDark) {
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
              Row(
                children: [
                  Icon(Icons.add_circle_rounded, color: Colors.redAccent, size: 14.r),
                  SizedBox(width: 6.w),
                  Text(
                    "POSITIVE POLE SENSOR",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 10.sp,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              ScaleButton(
                onTap: () => _soundService.playTts(fullText.replaceAll('*', '')),
                child: Icon(Icons.volume_up_rounded, color: Colors.redAccent, size: 18.r),
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
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 1.5.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Text(
                          e.value,
                          style: GoogleFonts.fredoka(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
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

  Widget _buildPlasmaConduitPanel(Color primaryColor, bool isDark) {
    return Container(
      width: 1.sw,
      height: 160.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C16) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Stack(
          children: [
            // Dynamic energy wave background
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isListening ? 0.3 : 0.05,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.redAccent, Colors.cyanAccent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            
            // Plasma CustomPaint
            Positioned.fill(
              child: CustomPaint(
                painter: PlasmaPainter(
                  progress: _pullProgress,
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

  Widget _buildNegativePolePanel(bool isDark) {
    final bool charged = _pullProgress > 0.95;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: charged
            ? Colors.cyanAccent.withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF131326) : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: charged ? Colors.cyanAccent : Colors.cyanAccent.withValues(alpha: 0.25),
          width: 1.5.r,
        ),
        boxShadow: charged
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  blurRadius: 15.r,
                )
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.remove_circle_rounded,
            color: charged ? Colors.cyanAccent : Colors.cyanAccent.withValues(alpha: 0.6),
            size: 16.r,
          ),
          SizedBox(width: 10.w),
          Text(
            charged ? "POLAR FUSION SECURED!" : "NEGATIVE POLE ANTIPODE",
            style: GoogleFonts.shareTechMono(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: charged ? Colors.cyanAccent : Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyTelemetryCard(bool isDark) {
    final bool hasInput = _spokenText != "Calibrating reverse polarization channel..." && _spokenText != "No magnetic frequency detected.";

    return GlassTile(
      padding: EdgeInsets.all(18.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hasInput ? Icons.flash_on_rounded : Icons.warning_amber_rounded,
                color: Colors.cyanAccent,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "DECODED REVERSE FREQUENCY",
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

  Widget _buildExplanationCard(GameQuest quest, bool isDark) {
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
                (_isCorrect ?? false) ? Icons.offline_bolt_rounded : Icons.gavel_rounded,
                color: cardColor,
                size: 24.r,
              ),
              SizedBox(width: 8.w),
              Text(
                (_isCorrect ?? false) ? "Opposite Fused!" : "Polar Bridge Collasped",
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
            quest.explanation ?? "Identifying direct lexical antonyms enhances cognitive mapping and communication depth.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
          if (!(_isCorrect ?? false) && _acceptedAntonyms.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Text(
              "ACCEPTED OPPOSITES:",
              style: GoogleFonts.shareTechMono(
                fontSize: 10.sp,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: _acceptedAntonyms.map((s) => Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.fredoka(
                    fontSize: 12.sp,
                    color: Colors.redAccent,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildElectromagneticTrigger(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _startSpeechListening(),
      onLongPressEnd: (_) => _stopSpeechListening(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Circular charging field while recording is active
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

              // Outer hub border
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: _isListening
                        ? Colors.cyanAccent.withValues(alpha: 0.3)
                        : Colors.redAccent.withValues(alpha: 0.1),
                    width: 4.r,
                  ),
                ),
              ).animate(target: _isListening ? 1 : 0).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.18, 1.18),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  ),

              // Interactive Mic capsule button
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [Colors.teal[900]!, Colors.cyanAccent]
                          : [const Color(0xFF1F1C2C), const Color(0xFF928DAB)],
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
                    _isListening ? Icons.flash_on_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _isListening ? "RELEASE CAN TO INJECT FREQUENCY" : "HOLD TO BRIDGE POLAR OPPOSITE",
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
