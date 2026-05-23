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

class SpeedVarianceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeedVarianceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speedVariance,
  });

  @override
  State<SpeedVarianceScreen> createState() => _SpeedVarianceScreenState();
}

class _SpeedVarianceScreenState extends State<SpeedVarianceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _dialRotation = 0.0;
  bool _isDragging = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _onDialRotate(DragUpdateDetails details, int correct) {
    if (_isAnswered) return;
    setState(() {
      _isDragging = true;
      _dialRotation = (_dialRotation + details.delta.dx / 100.0).clamp(-1.0, 1.0);
    });
    _hapticService.selection();

    // Auto-lock when reaching ends
    if (_dialRotation < -0.6) {
      _submitChoice(0, correct);
    } else if (_dialRotation > 0.6) {
      _submitChoice(1, correct);
    }
  }

  void _onDialRelease() {
    if (_isAnswered || !_isDragging) return;
    setState(() {
      _isDragging = false;
      if (!_isAnswered) {
        _dialRotation = 0.0;
      }
    });
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered) return;
    setState(() {
      _selectedIndex = index;
      _dialRotation = index == 0 ? -0.8 : 0.8;
      _isDragging = false;
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
            _dialRotation = 0.0;
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
              _dialRotation = 0.0;
              _selectedIndex = null;
              _isDragging = false;
            });
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'TEMPO ACE!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded) ? state.currentQuest as AccentQuest? : null;
        final options = quest?.options ?? ["A", "B"];

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
                  
                  _buildPulseSpeaker(quest.textToSpeak ?? "", theme.primaryColor),
                  SizedBox(height: 32.h),
                  
                  _buildTempoDial(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
                  
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
          Icon(Icons.speed_rounded, size: 14.r, color: color),
          SizedBox(width: 12.w),
          Text("IDENTIFY SPEED VARIANCE CONTOUR & PACING INTENT ENUNCIATED", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
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
                  "DRILLED SENTENCE", 
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
                "HEAR SPEED",
                style: GoogleFonts.shareTechMono(color: color, fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 1)
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTempoDial(List<String> options, int correct, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildConnectedSpeechOrb(options[0], 0, correct, color, isDark)),
            SizedBox(width: 12.w),
            _buildChromeDial(correct, color, isDark),
            SizedBox(width: 12.w),
            Expanded(child: _buildConnectedSpeechOrb(options[1], 1, correct, color, isDark)),
          ],
        ),
        SizedBox(height: 24.h),
        Text(
          _isDragging ? "MAINTAINING SPEED..." : "ROTATE DIAL OR TAP PREFERENCE", 
          style: GoogleFonts.shareTechMono(
            fontSize: 10.sp, 
            fontWeight: FontWeight.bold, 
            color: color.withValues(alpha: 0.8),
            letterSpacing: 1
          )
        ),
      ],
    );
  }

  Widget _buildChromeDial(int correct, Color color, bool isDark) {
    return Center(
      child: GestureDetector(
        onPanUpdate: (details) => _onDialRotate(details, correct),
        onPanEnd: (_) => _onDialRelease(),
        child: Transform.rotate(
          angle: _dialRotation,
          child: Container(
            width: 100.r, height: 100.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200, 
                  isDark ? Colors.black : Colors.grey.shade400
                ]
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54, 
                  blurRadius: 10, 
                  offset: const Offset(3, 3)
                )
              ],
              border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
            ),
            child: Center(
              child: Container(
                width: 10.r, height: 45.r,
                margin: EdgeInsets.only(bottom: 45.r),
                decoration: BoxDecoration(
                  color: color, 
                  borderRadius: BorderRadius.circular(5.r),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 5)
                  ]
                ),
              ),
            ),
          ),
        ),
      ),
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
        height: 120.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
              fontSize: 11.sp, 
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
            correct ? "CORRECT SPEED MATCH!" : "INCORRECT SPEED MATCH",
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
