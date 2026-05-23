import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

class PitchPatternMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PitchPatternMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pitchPatternMatch,
  });

  @override
  State<PitchPatternMatchScreen> createState() => _PitchPatternMatchScreenState();
}

class _PitchPatternMatchScreenState extends State<PitchPatternMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _sliderValue = 0.5;
  int? _selectedIndex;

  // Blueprint wave preview parameter
  double _previewProgress = 0.0;
  bool _isPreviewing = false;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
    _triggerPreviewWave();
  }

  void _triggerPreviewWave() {
    _previewTimer?.cancel();
    setState(() {
      _previewProgress = 0.0;
      _isPreviewing = true;
    });

    const steps = 30;
    const interval = Duration(milliseconds: 40);
    int currentStep = 0;

    _previewTimer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      setState(() {
        _previewProgress = (currentStep / steps).clamp(0.0, 1.0);
      });
      if (currentStep >= steps) {
        timer.cancel();
        setState(() => _isPreviewing = false);
      }
    });
  }

  void _onSliderUpdate(double value, int correct) {
    if (_isAnswered) return;
    setState(() => _sliderValue = value);
    
    // Auto-lock when reaching ends
    if (value < 0.1) {
      _submitChoice(0, correct);
    } else if (value > 0.9) {
      _submitChoice(1, correct);
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered) return;
    setState(() {
      _selectedIndex = index;
      _sliderValue = index == 0 ? 0.0 : 1.0;
    });
    
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<AccentBloc>().add(SubmitAnswer(false));
      
      Future.delayed(2.seconds, () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _selectedIndex = null;
            _sliderValue = 0.5;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _sliderValue = 0.5;
              _selectedIndex = null;
              _previewProgress = 0.0;
              _isPreviewing = false;
            });
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                  _triggerPreviewWave();
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'MELODY SYNCER!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded) ? state.currentQuest as AccentQuest? : null;
        final options = quest?.options ?? ["A", "B"];
        final pattern = quest?.pitchPatterns ?? [0, 1, 2, 1, 0];

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildInstruction(theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  _buildPromptCard(quest.word ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 24.h),
                  
                  _buildMelodicCanvas(pattern, theme.primaryColor, isDark),
                  SizedBox(height: 32.h),
                  
                  _buildPulseSpeaker(quest.textToSpeak ?? "", theme.primaryColor),
                  SizedBox(height: 48.h),
                  
                  _buildSpectralSlider(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 40.h),
                    _buildResultExplanation(quest, theme.primaryColor, isDark),
                  ],
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note_rounded, size: 14.r, color: color),
          SizedBox(width: 12.w),
          Text("IDENTIFY THE PITCH BLUEPRINT MATCHING NUCLEAR STRESS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPromptCard(String word, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 2),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Center(
            child: Column(
              children: [
                Text(
                  "TARGET SENTENCE", 
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10.sp, 
                    fontWeight: FontWeight.bold, 
                    color: color, 
                    letterSpacing: 2
                  )
                ),
                SizedBox(height: 8.h),
                Text(
                  word, 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 22.sp, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white : Colors.black87, 
                    letterSpacing: 1
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMelodicCanvas(List<int> pattern, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      height: 140.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12)
      ),
      child: Stack(
        children: [
          // Blueprint
          Center(
            child: CustomPaint(
              size: Size(0.7.sw, 100.h),
              painter: _BlueprintPainter(pattern, color.withValues(alpha: 0.2)),
            ),
          ),
          // User Ink/Glow Progress
          if (_isPreviewing || _isAnswered)
            Center(
              child: CustomPaint(
                size: Size(0.7.sw, 100.h),
                painter: _BlueprintPainter(pattern, color, progress: _isPreviewing ? _previewProgress : 1.0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPulseSpeaker(String text, Color color) {
    return ScaleButton(
      onTap: () => _playTts(text),
      child: Container(
        width: 110.r, height: 110.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20)
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq_rounded, color: color, size: 36.r)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
              SizedBox(height: 6.h),
              Text(
                "HEAR STRESS",
                style: GoogleFonts.shareTechMono(color: color, fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 1)
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpectralSlider(List<String> options, int correct, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildConnectedSpeechOrb(options[0], 0, correct, color, isDark)),
            SizedBox(width: 16.w),
            Expanded(child: _buildConnectedSpeechOrb(options[1], 1, correct, color, isDark)),
          ],
        ),
        SizedBox(height: 32.h),
        _buildSliderBar(correct, color),
      ],
    );
  }

  Widget _buildConnectedSpeechOrb(String text, int index, int correctIndex, Color color, bool isDark) {
    final bool isSelected = _selectedIndex == index;
    final bool correct = index == correctIndex;
    
    Color orbColor = color.withValues(alpha: 0.1);
    Color textColor = color;
    if (_isAnswered && isSelected) {
      orbColor = correct ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2);
      textColor = correct ? Colors.greenAccent : Colors.redAccent;
    } else if (isSelected) {
      orbColor = color;
      textColor = Colors.white;
    }

    return ScaleButton(
      onTap: () => _submitChoice(index, correctIndex),
      child: Container(
        height: 100.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: orbColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _isAnswered && isSelected 
              ? textColor 
              : color.withValues(alpha: isSelected ? 1.0 : 0.3), 
            width: 3
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? (correct ? Colors.greenAccent.withValues(alpha: 0.3) : color.withValues(alpha: 0.3)) 
                : Colors.transparent, 
              blurRadius: 15
            )
          ],
        ),
        child: Center(
          child: Text(
            text, 
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              fontSize: 12.sp, 
              fontWeight: FontWeight.bold, 
              color: textColor,
              height: 1.2
            )
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: (2 + index).seconds),
    );
  }

  Widget _buildSliderBar(int correct, Color color) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: color,
        inactiveTrackColor: color.withValues(alpha: 0.1),
        thumbColor: color,
        overlayColor: color.withValues(alpha: 0.2),
        trackHeight: 10.h,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 16.r),
      ),
      child: Slider(
        value: _sliderValue,
        onChanged: (v) => _onSliderUpdate(v, correct),
      ),
    );
  }

  Widget _buildResultExplanation(AccentQuest quest, Color color, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: displayColor, size: 36.r),
          SizedBox(height: 10.h),
          Text(
            correct ? "CORRECT PITCH BLUEPRINT!" : "INCORRECT PITCH BLUEPRINT",
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}

class _BlueprintPainter extends CustomPainter {
  final List<int> pattern;
  final Color color;
  final double progress;
  _BlueprintPainter(this.pattern, this.color, {this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    if (pattern.isEmpty) return;

    double dx = size.width / (pattern.length - 1);
    path.moveTo(0, size.height - (pattern[0] / 4.0 * size.height));

    for (int i = 1; i < pattern.length; i++) {
      if (i / (pattern.length - 1) > progress) break;
      path.lineTo(i * dx, size.height - (pattern[i] / 4.0 * size.height));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
