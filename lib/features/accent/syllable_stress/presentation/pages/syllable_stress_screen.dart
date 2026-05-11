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

class SyllableStressScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SyllableStressScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.syllableStress,
  });

  @override
  State<SyllableStressScreen> createState() => _SyllableStressScreenState();
}

class _SyllableStressScreenState extends State<SyllableStressScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _selectedIndex;
  final List<int> _tapSequence = [];

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onPadTap(int index, int correct, int total) {
    if (_isAnswered) return;
    
    setState(() {
      _selectedIndex = index;
      if (index == correct) {
         _hapticService.success(); // Stronger haptic for stress
      } else {
         _hapticService.selection();
      }
    });

    if (index == correct) {
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
              _selectedIndex = null;
              _tapSequence.clear();
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'RHYTHM MASTER!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is AccentLoaded) ? state.currentQuest : null;
        final syllables = quest?.syllables ?? [];

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildWordDisplay(quest.word ?? "", theme.primaryColor, isDark),
              _buildDrumConsole(syllables, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
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
        child: Text("STRIKE THE STRESSED SYLLABLE PAD", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildWordDisplay(String word, Color color, bool isDark) {
    return Positioned(
      top: 80.h,
      child: GestureDetector(
        onTap: () => _soundService.playTts(word),
        child: Column(
          children: [
            Icon(Icons.speaker_group_rounded, color: color, size: 40.r),
            SizedBox(height: 12.h),
            Text(word.toUpperCase(), style: GoogleFonts.outfit(fontSize: 32.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 6)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrumConsole(List<String> syllables, int correct, Color color, bool isDark) {
    return Positioned(
      bottom: 100.h,
      child: Wrap(
        spacing: 20.w,
        runSpacing: 20.h,
        alignment: WrapAlignment.center,
        children: List.generate(syllables.length, (i) => _buildDrumPad(i, syllables[i], correct, color, isDark)),
      ),
    );
  }

  Widget _buildDrumPad(int index, String text, int correct, Color color, bool isDark) {
    bool isSelected = _selectedIndex == index;
    bool isCorrect = _isAnswered && index == correct;
    bool isWrong = _isAnswered && isSelected && index != correct;
    Color padColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : color);

    return ScaleButton(
      onTap: () => _onPadTap(index, correct, 0),
      child: AnimatedContainer(
        duration: 100.ms,
        width: 140.r, height: 140.r,
        decoration: BoxDecoration(
          color: isSelected ? padColor.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? padColor : color.withValues(alpha: 0.2), width: 3),
          boxShadow: isSelected ? [BoxShadow(color: padColor.withValues(alpha: 0.3), blurRadius: 20)] : [],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isSelected ? padColor : (isDark ? Colors.white : Colors.black87))),
              if (index == correct && _isAnswered) Icon(Icons.bolt_rounded, color: Colors.greenAccent, size: 24.r),
            ],
          ),
        ),
      ),
    );
  }
}

