import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';

import 'package:flutter_animate/flutter_animate.dart';

class PitchModulationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PitchModulationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pitchModulation,
  });

  @override
  State<PitchModulationScreen> createState() => _PitchModulationScreenState();
}

class _PitchModulationScreenState extends State<PitchModulationScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _dialRotation = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onDialRotate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _isDragging = true;
      _dialRotation += details.delta.dx / 100.0;
    });
    _hapticService.selection();
  }

  void _onDialRelease() {
    if (_isAnswered || !_isDragging) return;
    setState(() => _isDragging = false);
    _submitAnswer();
  }

  void _submitAnswer() {
    _soundService.playCorrect();
    _hapticService.success();
    setState(() { _isAnswered = true; _isCorrect = true; });
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
              _dialRotation = 0.0;
              _isDragging = false;
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'TONAL EXPERT!', enableDoubleUp: true);
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
              _buildStudioHeader(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              _buildModulationDial(theme.primaryColor, isDark),
              _buildStudioControls(theme.primaryColor),
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
        child: Text("ROTATE THE MODULATION DIAL TO MATCH THE INFLECTION", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildStudioHeader(String text, Color color, bool isDark) {
    return Positioned(
      top: 100.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: () => _speechService.speak(text),
            child: Icon(Icons.settings_voice_rounded, color: color, size: 40.r),
          ),
          SizedBox(height: 20.h),
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildModulationDial(Color color, bool isDark) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Studio Rack
          Container(
            width: 260.r, height: 260.r,
            decoration: BoxDecoration(
              color: isDark ? Colors.black54 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: color.withValues(alpha: 0.1), width: 4),
            ),
          ),
          // Chrome Dial
          GestureDetector(
            onPanUpdate: _onDialRotate,
            onPanEnd: (_) => _onDialRelease(),
            child: Transform.rotate(
              angle: _dialRotation,
              child: Container(
                width: 200.r, height: 200.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [isDark ? Colors.grey.shade800 : Colors.grey.shade200, isDark ? Colors.black : Colors.grey.shade400]),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(5, 5))],
                ),
                child: Center(
                  child: Container(
                    width: 120.r, height: 120.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Icon(Icons.show_chart_rounded, color: Colors.green, size: 48.r)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioControls(Color color) {
    return Positioned(
      bottom: 80.h,
      child: Column(
        children: [
          Icon(_isDragging ? Icons.mic_rounded : Icons.mic_none_rounded, color: color, size: 48.r),
          SizedBox(height: 12.h),
          Text(_isDragging ? "MODULATING TONE..." : "GRAB DIAL AND MATCH", style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

