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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class WordReorderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordReorderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordReorder,
  });

  @override
  State<WordReorderScreen> createState() => _WordReorderScreenState();
}

class _WordReorderScreenState extends State<WordReorderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  List<String>? _availableWords;
  List<String> _assembledWords = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onWordTap(String word, String correctAnswer) {
    final cleanCorrectAnswer = correctAnswer.replaceAll(RegExp(r'[.!?,"\u0027]'), '').trim();
    final correctWords = cleanCorrectAnswer.split(' ');
    
    if (_assembledWords.length >= correctWords.length) return;
    
    final nextCorrectWord = correctWords[_assembledWords.length];
    
    // Strip punctuation from the tapped word too for comparison
    final cleanTappedWord = word.replaceAll(RegExp(r'[.!?,"\u0027]'), '').trim();

    if (cleanTappedWord.toLowerCase() == nextCorrectWord.toLowerCase()) {
      _hapticService.selection();
      _soundService.playCorrect();
      setState(() {
        _assembledWords.add(word);
        _availableWords!.remove(word);
        
        if (_assembledWords.length == correctWords.length) {
          _submitAnswer(correctAnswer);
        }
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitAnswer(String correctAnswer) {
    _hapticService.success();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<GrammarBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _availableWords = null;
              _assembledWords = [];
            });
          }
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX SHARPSHOOTER!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        if (quest != null && _availableWords == null) {
          _availableWords = List.from(quest.shuffledWords ?? []);
        }
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 20.h),
              
              // Optimized: Concise Assembly Card (The Diamond Standard)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: 120.h),
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: Center(
                    child: Wrap(
                      spacing: 8.w, 
                      runSpacing: 10.h,
                      alignment: WrapAlignment.center,
                      children: _assembledWords.isEmpty 
                        ? [
                            Text(
                              "WAITING FOR DATA...", 
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp, 
                                fontWeight: FontWeight.w700,
                                color: theme.primaryColor.withValues(alpha: 0.3),
                                letterSpacing: 2
                              )
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds)
                          ]
                        : _assembledWords.map((word) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              word, 
                              style: GoogleFonts.fredoka(
                                fontSize: 18.sp, 
                                fontWeight: FontWeight.w600, 
                                color: theme.primaryColor
                              )
                            ),
                          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)).toList(),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

              SizedBox(height: 50.h),
              
              // The Magnetic Floating Field
              Expanded(
                child: _buildGravityFallArea(quest.sentence ?? "", theme.primaryColor, isDark),
              ),
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
          Icon(Icons.auto_fix_high_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("CATCH WORDS IN ORDER", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildGravityFallArea(String correctAnswer, Color primaryColor, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 16.h,
        alignment: WrapAlignment.center,
        children: _availableWords!.asMap().entries.map((entry) {
          return _FloatingWordTile(
            word: entry.value,
            index: entry.key,
            onTap: () => _onWordTap(entry.value, correctAnswer),
            primaryColor: primaryColor,
            isDark: isDark,
          );
        }).toList(),
      ),
    );
  }
}

class _FloatingWordTile extends StatelessWidget {
  final String word;
  final int index;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;

  const _FloatingWordTile({
    required this.word, 
    required this.index, 
    required this.onTap, 
    required this.primaryColor, 
    required this.isDark
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Text(
          word, 
          style: GoogleFonts.outfit(
            fontSize: 16.sp, 
            fontWeight: FontWeight.w700, 
            color: isDark ? Colors.white : Colors.black87
          )
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .moveY(begin: -5, end: 5, duration: (2000 + (index * 200)).ms, curve: Curves.easeInOutSine)
     .shimmer(delay: (index * 100).ms, duration: 2.seconds, color: Colors.white10);
  }
}

