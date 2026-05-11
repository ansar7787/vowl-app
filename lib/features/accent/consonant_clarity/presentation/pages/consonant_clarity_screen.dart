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

class ConsonantClarityScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConsonantClarityScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.consonantClarity,
  });

  @override
  State<ConsonantClarityScreen> createState() => _ConsonantClarityScreenState();
}

class _ConsonantClarityScreenState extends State<ConsonantClarityScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isRecording = false;
  int _shatterCount = 0;
  double _orbRotation = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onTargetTap() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _isRecording = true;
      _shatterCount++;
      _orbRotation += 0.5;
    });

    if (_shatterCount >= 3) {
       _submitAnswer();
    }
  }

  void _submitAnswer() {
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; _isRecording = false; });
    context.read<AccentBloc>().add(SubmitAnswer(true));
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
              _isRecording = false;
              _shatterCount = 0;
              _orbRotation = 0.0;
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'ENUNCIATION ACE!', enableDoubleUp: true);
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
              _buildWordDisplay(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              _buildCrystallineOrb(theme.primaryColor, isDark),
              _buildShatterProgress(theme.primaryColor),
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
        child: Text("TAP AND ENUNCIATE TO SHATTER THE SHIELD", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildWordDisplay(String word, Color color, bool isDark) {
    return Positioned(
      top: 80.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: () => _soundService.playTts(word),
            child: Icon(Icons.record_voice_over_rounded, color: color, size: 40.r),
          ),
          SizedBox(height: 12.h),
          Text(word.toUpperCase(), style: GoogleFonts.outfit(fontSize: 32.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 8)),
        ],
      ),
    );
  }

  Widget _buildCrystallineOrb(Color color, bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _onTargetTap,
        child: Transform.rotate(
          angle: _orbRotation,
          child: Container(
            width: 200.r, height: 200.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.1), Colors.transparent]),
              border: Border.all(color: color, width: 4),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10)],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.hexagon_rounded, size: 120.r, color: color.withValues(alpha: 0.3)),
                if (_isRecording) Icon(Icons.mic_rounded, color: Colors.white, size: 40.r).animate().scale(duration: 200.ms),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05)),
        ),
      ),
    );
  }

  Widget _buildShatterProgress(Color color) {
    return Positioned(
      bottom: 100.h,
      child: Row(
        children: List.generate(3, (i) => Container(
          width: 40.w, height: 8.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: i < _shatterCount ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4.r),
            boxShadow: i < _shatterCount ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)] : [],
          ),
        )),
      ),
    );
  }
}
