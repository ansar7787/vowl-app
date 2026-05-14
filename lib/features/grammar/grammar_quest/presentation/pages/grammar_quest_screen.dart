import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class GrammarQuestScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GrammarQuestScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.grammarQuest,
  });

  @override
  State<GrammarQuestScreen> createState() => _GrammarQuestScreenState();
}

class _GrammarQuestScreenState extends State<GrammarQuestScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _needleRotation = 0.0; // In radians
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onQuadrantSelect(int index, int correctIndex) {
    if (_isAnswered) return;
    
    // Snap needle to quadrant center
    setState(() {
      _needleRotation = (index * (3.14159 * 2) / 4);
    });
    
    _hapticService.selection();

    bool isCorrect = index == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _needleRotation = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SENTINEL!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["Subject", "Verb", "Object", "Tense"]; // Fallback options
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 20.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildSentenceDisplay(quest.sentence ?? quest.question ?? "", theme.primaryColor, isDark),
              SizedBox(height: 60.h),
              _buildQuestCompass(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("STEER TO THE CORRECT RULE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSentenceDisplay(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(28.r),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 20.sp, color: isDark ? Colors.white : Colors.black87, height: 1.4)),
    );
  }

  Widget _buildQuestCompass(List<String> options, int correctIndex, Color primaryColor, bool isDark) {
    return Container(
      width: 280.r, height: 280.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 4.r),
        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 10)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Quadrants
          ...List.generate(4, (index) {
            final angle = index * (3.14159 * 2) / 4;
            final optionText = index < options.length ? options[index] : "";
            return Transform.rotate(
              angle: angle,
              child: GestureDetector(
                onTap: () => _onQuadrantSelect(index, correctIndex),
                child: Container(
                  width: 280.r, height: 280.r,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 20.r, left: 0, right: 0,
                        child: Transform.rotate(
                          angle: -angle,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(8.r),
                              width: 80.r,
                              child: Text(optionText, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor.withValues(alpha: 0.7), letterSpacing: 1)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          // Center Dial
          Container(
            width: 40.r, height: 40.r,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 10)]),
          ),
          // Needle
          AnimatedRotation(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            turns: _needleRotation / (2 * 3.14159),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 4.w, height: 180.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [primaryColor, primaryColor.withValues(alpha: 0.2)],
                    ),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Container(
                    width: 16.r, height: 16.r,
                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
