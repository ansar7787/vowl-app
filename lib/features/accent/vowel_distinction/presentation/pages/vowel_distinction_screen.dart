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

class VowelDistinctionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const VowelDistinctionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.vowelDistinction,
  });

  @override
  State<VowelDistinctionScreen> createState() => _VowelDistinctionScreenState();
}

class _VowelDistinctionScreenState extends State<VowelDistinctionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _sliderValue = 0.5;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onSliderUpdate(double value, int correct) {
    if (_isAnswered) return;
    setState(() => _sliderValue = value);
    
    // Check if reached ends
    if (value < 0.1) {
      _submitChoice(0, correct);
    } else if (value > 0.9) {
      _submitChoice(1, correct);
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered) return;
    setState(() => _selectedIndex = index);
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
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _sliderValue = 0.5;
              _selectedIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'PHONEME PRO!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is AccentLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["A", "B"];

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildSpectrumCenter(quest.word ?? "", theme.primaryColor, isDark),
              _buildSpectralSlider(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
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
        child: Text("SLIDE THE NEEDLE TO FUSE WITH THE CORRECT VOWEL", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSpectrumCenter(String word, Color color, bool isDark) {
    return Positioned(
      top: 100.h,
      child: GestureDetector(
        onTap: () => _soundService.playTts(word),
        child: Column(
          children: [
            Icon(Icons.graphic_eq_rounded, color: color, size: 50.r).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
            SizedBox(height: 20.h),
            Text(word.toUpperCase(), style: GoogleFonts.outfit(fontSize: 32.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 4)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpectralSlider(List<String> options, int correct, Color color, bool isDark) {
    return Positioned(
      bottom: 120.h,
      child: SizedBox(
        width: 0.9.sw,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildVowelOrb(options[0], 0, color),
                _buildVowelOrb(options[1], 1, color),
              ],
            ),
            SizedBox(height: 40.h),
            _buildSliderBar(correct, color),
          ],
        ),
      ),
    );
  }

  Widget _buildVowelOrb(String text, int index, Color color) {
    bool isTarget = _selectedIndex == index;
    return Container(
      width: 80.r, height: 80.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isTarget ? color : color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 2),
        boxShadow: isTarget ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)] : [],
      ),
      child: Center(
        child: Text(text, style: GoogleFonts.shareTechMono(fontSize: 24.sp, fontWeight: FontWeight.bold, color: isTarget ? Colors.white : color)),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: (2 + index).seconds);
  }

  Widget _buildSliderBar(int correct, Color color) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: color,
        inactiveTrackColor: color.withValues(alpha: 0.1),
        thumbColor: color,
        overlayColor: color.withValues(alpha: 0.2),
        trackHeight: 12.h,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 15.r),
      ),
      child: Slider(
        value: _sliderValue,
        onChanged: (v) => _onSliderUpdate(v, correct),
      ),
    );
  }
}

