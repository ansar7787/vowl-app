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

class SentenceCorrectionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SentenceCorrectionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceCorrection,
  });

  @override
  State<SentenceCorrectionScreen> createState() => _SentenceCorrectionScreenState();
}

class _SentenceCorrectionScreenState extends State<SentenceCorrectionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  int? _tappedIndex;
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

  void _onZap(int index, int correctIndex) {
    if (_isAnswered) return;
    setState(() => _tappedIndex = index);

    bool isCorrect = index == correctIndex;

    if (isCorrect) {
      _hapticService.heavy();
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
              _tappedIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX SURGEON!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final rawSentence = quest?.sentence ?? "";
        final cleanSentence = rawSentence.replaceAll('"', '').replaceAll('Fix:', '').trim();
        final words = cleanSentence.split(' ');
        
        // Find the index of the incorrect part in the words list
        // Note: JSON correctAnswerIndex often refers to the options array, 
        // so we derive the word index from incorrectPart field.
        int correctWordIndex = -1;
        if (quest != null && quest.incorrectPart != null) {
          final target = quest.incorrectPart!.toLowerCase().replaceAll('"', '').trim();
          correctWordIndex = words.indexWhere((w) => w.toLowerCase().contains(target));
        }
        // Fallback to quest.correctAnswerIndex if incorrectPart search fails
        if (correctWordIndex == -1) correctWordIndex = quest?.correctAnswerIndex ?? 0;
        
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
              SizedBox(height: 32.h),
              
              // Optimized: Kinetic Diagnostic Context Card (The Diamond Standard)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(32.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: theme.primaryColor.withValues(alpha: 0.05), blurRadius: 40, spreadRadius: 5)
                    ],
                  ),
                  child: _buildZapperGrid(words, correctWordIndex, theme.primaryColor, isDark),
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),

              SizedBox(height: 48.h),
              _buildDiagnosticStatus(theme.primaryColor),
              const Spacer(),
              if (_isAnswered && _isCorrect == false)
                _buildCorrectionFeed(quest.correctedPart ?? "", theme.primaryColor),
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
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.biotech_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "INITIATE LINGUISTIC SCAN", 
            style: GoogleFonts.outfit(
              fontSize: 10.sp, 
              fontWeight: FontWeight.w900, 
              color: primaryColor, 
              letterSpacing: 1.5
            )
          ),
        ],
      ),
    );
  }

  Widget _buildZapperGrid(List<String> words, int correctIndex, Color primaryColor, bool isDark) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10.w,
      runSpacing: 16.h,
      children: List.generate(words.length, (i) => _buildDiagnosticWord(words[i], i, correctIndex, primaryColor, isDark)),
    );
  }

  Widget _buildDiagnosticWord(String text, int index, int correctIndex, Color primaryColor, bool isDark) {
    final isTapped = _tappedIndex == index;
    final isCorrect = _isAnswered && _isCorrect == true && index == correctIndex;
    final isWrong = _isAnswered && _isCorrect == false && isTapped;

    return GestureDetector(
      onTap: () => _onZap(index, correctIndex),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isCorrect 
              ? Colors.greenAccent.withValues(alpha: 0.15) 
              : (isWrong ? Colors.redAccent.withValues(alpha: 0.15) : Colors.transparent),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isCorrect 
                ? Colors.greenAccent 
                : (isWrong ? Colors.redAccent : primaryColor.withValues(alpha: 0.1)), 
            width: isCorrect || isWrong ? 2 : 1
          ),
          boxShadow: [
            if (isCorrect) BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 15),
            if (isWrong) BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 15),
          ],
        ),
        child: Text(
          text, 
          style: GoogleFonts.fredoka(
            fontSize: 22.sp, 
            fontWeight: isCorrect || isWrong ? FontWeight.bold : FontWeight.normal,
            color: isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : (isDark ? Colors.white : Colors.black87)),
            decoration: isWrong ? TextDecoration.lineThrough : null,
          )
        ),
      ).animate(target: isTapped ? 1 : 0)
       .shimmer(duration: 400.ms, color: isCorrect ? Colors.greenAccent : Colors.redAccent)
       .shake(duration: 300.ms, hz: isWrong ? 10 : 0)
       .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildDiagnosticStatus(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10.r, height: 10.r,
          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(1, 1), end: const Offset(1.8, 1.8), duration: 1.seconds)
         .shimmer(color: primaryColor),
        SizedBox(width: 14.w),
        Text(
          "SCANNER ARMED: SEEKING GLITCHES", 
          style: GoogleFonts.outfit(
            fontSize: 10.sp, 
            fontWeight: FontWeight.w900, 
            color: primaryColor, 
            letterSpacing: 2
          )
        ),
      ],
    );
  }

  Widget _buildCorrectionFeed(String correction, Color primaryColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            "GLITCH RESOLUTION", 
            style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 1.5)
          ),
          SizedBox(height: 8.h),
          Text(
            "Correction: $correction", 
            style: GoogleFonts.fredoka(fontSize: 18.sp, color: Colors.redAccent, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

