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

class MinimalPairsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const MinimalPairsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.minimalPairs,
  });

  @override
  State<MinimalPairsScreen> createState() => _MinimalPairsScreenState();
}

class _MinimalPairsScreenState extends State<MinimalPairsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _selectedDroneIndex;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _onShoot(int index, int correctIndex) {
    if (_isAnswered) return;
    
    final bool correct = index == correctIndex;
    setState(() {
      _selectedDroneIndex = index;
    });

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = true; 
      });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false; 
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));
      
      Future.delayed(2.seconds, () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _selectedDroneIndex = null;
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
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedDroneIndex = null;
            });
            // Proactively auto-play phonetic sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'PHONETIC EXPERT!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded) ? state.currentQuest as AccentQuest? : null;

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
                  
                  _buildPromptCard(theme.primaryColor, isDark),
                  SizedBox(height: 32.h),
                  
                  _buildSpeakerCore(quest.textToSpeak ?? "", theme.primaryColor),
                  SizedBox(height: 40.h),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDroneOption(0, quest.word1 ?? "", quest.ipa1 ?? "", quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
                      _buildDroneOption(1, quest.word2 ?? "", quest.ipa2 ?? "", quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
                    ],
                  ),
                  
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
          Icon(Icons.hearing_rounded, size: 14.r, color: color),
          SizedBox(width: 12.w),
          Text("LISTEN TO TARGET SOUND & IDENTIFY THE DRONE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPromptCard(Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 2),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Text(
            "Phonetic contrasts differentiate pairs of words by just one vital vowel or consonant phoneme. Can you distinguish the precise organic difference?",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerCore(String text, Color color) {
    return ScaleButton(
      onTap: () => _playTts(text),
      child: Container(
        width: 130.r, height: 130.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 2)
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.record_voice_over_rounded, color: color, size: 40.r),
              SizedBox(height: 6.h),
              Text(
                "TAP TO PLAY",
                style: GoogleFonts.shareTechMono(color: color, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 1)
              )
            ],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.06, 1.06), duration: 1.5.seconds),
    );
  }

  Widget _buildDroneOption(int index, String word, String ipa, int correctIndex, Color color, bool isDark) {
    final bool isSelected = _selectedDroneIndex == index;
    final bool correct = index == correctIndex;
    
    Color borderColor = color.withValues(alpha: 0.3);
    if (_isAnswered && isSelected) {
      borderColor = correct ? Colors.greenAccent : Colors.redAccent;
    } else if (isSelected) {
      borderColor = color;
    }

    return ScaleButton(
      onTap: () => _onShoot(index, correctIndex),
      child: Column(
        children: [
          AnimatedContainer(
            duration: 250.milliseconds,
            width: 130.w, height: 110.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.black45 : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: (isSelected && _isAnswered) 
                    ? (correct ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3))
                    : color.withValues(alpha: isDark ? 0.25 : 0.08), 
                  blurRadius: 10
                )
              ],
            ),
            child: Stack(
              children: [
                const TechPatternOverlay(opacity: 0.05),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        word.toUpperCase(), 
                        style: GoogleFonts.shareTechMono(
                          fontSize: 18.sp, 
                          fontWeight: FontWeight.bold, 
                          color: isDark ? Colors.white : Colors.black87
                        )
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r)
                        ),
                        child: Text(
                          ipa, 
                          style: GoogleFonts.shareTechMono(
                            fontSize: 11.sp, 
                            fontWeight: FontWeight.bold,
                            color: color
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: index == 0 ? 8.h : -8.h, duration: (2 + index).seconds),
          
          if (_isAnswered && isSelected) ...[
            SizedBox(height: 10.h),
            Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: correct ? Colors.greenAccent : Colors.redAccent,
              size: 20.r,
            ).animate().scale(),
          ]
        ],
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
            correct ? "CORRECT SOUND!" : "INCORRECT SOUND",
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
