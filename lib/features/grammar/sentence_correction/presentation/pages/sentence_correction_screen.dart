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
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
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
        final words = (quest?.sentence ?? "").split(' ');
        
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
              SizedBox(height: 48.h),
              _buildZapperGrid(words, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              SizedBox(height: 60.h),
              _buildZapperFooter(theme.primaryColor),
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
          Icon(Icons.bolt_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("ZAP THE GLITCHED WORD", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildZapperGrid(List<String> words, int correctIndex, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(32.r),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12.w,
        runSpacing: 16.h,
        children: List.generate(words.length, (i) => _buildZappableWord(words[i], i, correctIndex, primaryColor, isDark)),
      ),
    );
  }

  Widget _buildZappableWord(String text, int index, int correctIndex, Color primaryColor, bool isDark) {
    final isTapped = _tappedIndex == index;
    final isCorrect = _isAnswered && _isCorrect == true && index == correctIndex;
    final isWrong = _isAnswered && _isCorrect == false && isTapped;

    return GestureDetector(
      onTap: () => _onZap(index, correctIndex),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isTapped)
            Container(
              width: 80.w, height: 80.h,
              decoration: BoxDecoration(shape: BoxShape.circle, color: (isCorrect ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.2)),
            ).animate().scale(duration: 200.ms).fadeOut(delay: 200.ms),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.greenAccent.withValues(alpha: 0.2) : (isWrong ? Colors.redAccent.withValues(alpha: 0.2) : Colors.transparent),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : Colors.transparent), width: 2),
            ),
            child: Text(
              text, 
              style: GoogleFonts.fredoka(
                fontSize: 22.sp, 
                color: isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : (isDark ? Colors.white : Colors.black87)),
                decoration: isWrong ? TextDecoration.lineThrough : null,
              )
            ),
          ).animate(target: isTapped ? 1 : 0).shake(duration: 300.ms).tint(color: isCorrect ? Colors.greenAccent : Colors.redAccent),
          
          if (isTapped)
            Icon(Icons.bolt_rounded, color: isCorrect ? Colors.greenAccent : Colors.redAccent, size: 40.r)
              .animate().scale(duration: 200.ms, curve: Curves.easeOutBack).shake(hz: 10).fadeOut(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildZapperFooter(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8.r, height: 8.r,
          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(2, 2), duration: 800.ms),
        SizedBox(width: 12.w),
        Text("ZAPPER ARMED", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 2)),
      ],
    );
  }
}

