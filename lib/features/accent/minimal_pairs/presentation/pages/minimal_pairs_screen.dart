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

import 'package:flutter_animate/flutter_animate.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onShoot(int index, int correct) {
    if (_isAnswered) return;
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
            });
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
        final quest = (state is AccentLoaded) ? state.currentQuest : null;

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildPulseCore(quest.textToSpeak ?? "", theme.primaryColor),
              if (!_isAnswered) _buildDrone(0, quest.word1 ?? "A", quest.ipa1 ?? "", quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              if (!_isAnswered) _buildDrone(1, quest.word2 ?? "B", quest.ipa2 ?? "", quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              if (_isAnswered) _buildResultFlash(theme.primaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Positioned(
      top: 20.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Text("LISTEN AND SHOOT THE CORRECT DRONE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildPulseCore(String text, Color color) {
    return Positioned(
      bottom: 60.h,
      child: GestureDetector(
        onTap: () {
           _hapticService.selection();
           _soundService.playTts(text);
        },
        child: Container(
          width: 120.r, height: 120.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 3),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 40)],
          ),
          child: Center(child: Icon(Icons.record_voice_over_rounded, color: color, size: 50.r)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1)),
      ),
    );
  }

  Widget _buildDrone(int index, String word, String ipa, int correct, Color color, bool isDark) {
    return Positioned(
      top: index == 0 ? 150.h : 300.h,
      left: index == 0 ? 40.w : null,
      right: index == 1 ? 40.w : null,
      child: GestureDetector(
        onTap: () => _onShoot(index, correct),
        child: Column(
          children: [
            Container(
              width: 120.w, height: 100.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: color, width: 2),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20)],
              ),
              child: Center(
                child: Text(word.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 18.sp, fontWeight: FontWeight.bold, color: color)),
              ),
            ),
            SizedBox(height: 8.h),
            Text(ipa, style: GoogleFonts.fredoka(fontSize: 10.sp, color: Colors.grey)),
          ],
        ).animate(onPlay: (c) => c.repeat(reverse: true)).moveX(begin: 0, end: index == 0 ? 20.w : -20.w, duration: (2 + index).seconds),
      ),
    );
  }

  Widget _buildResultFlash(Color color) {
    bool correct = _isCorrect ?? false;
    return Positioned.fill(
      child: Container(
        color: (correct ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
        child: Center(
          child: Icon(correct ? Icons.bolt_rounded : Icons.close_rounded, size: 100.r, color: correct ? Colors.greenAccent : Colors.redAccent),
        ),
      ).animate().fadeOut(duration: 500.ms),
    );
  }
}

