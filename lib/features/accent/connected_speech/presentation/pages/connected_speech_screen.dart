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

class ConnectedSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConnectedSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.connectedSpeech,
  });

  @override
  State<ConnectedSpeechScreen> createState() => _ConnectedSpeechScreenState();
}

class _ConnectedSpeechScreenState extends State<ConnectedSpeechScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _flowProgress = 0.0;
  bool _isFlowing = false;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onFlowUpdate(DragUpdateDetails details) {
    if (_isAnswered || !_isFlowing) return;
    setState(() {
      _flowProgress = (_flowProgress + (details.delta.dx / 1.sw)).clamp(0.0, 1.0);
    });
    _hapticService.selection();
  }

  void _onFlowStart() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _isFlowing = true;
      _flowProgress = 0.0;
    });
  }

  void _onFlowEnd() {
    if (_isAnswered || !_isFlowing) return;
    setState(() => _isFlowing = false);
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
              _flowProgress = 0.0;
              _isFlowing = false;
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'FLUENCY FLOW!', enableDoubleUp: true);
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
              _buildFlowDisplay(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              _buildLiquidStream(theme.primaryColor, isDark),
              _buildFlowAction(theme.primaryColor),
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
        child: Text("TRACE THE LIQUID FLOW WHILE LINKING WORDS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildFlowDisplay(String text, Color color, bool isDark) {
    return Positioned(
      top: 100.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: () => _speechService.speak(text),
            child: Icon(Icons.waves_rounded, color: color, size: 40.r),
          ),
          SizedBox(height: 20.h),
          Text(text.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 4)),
        ],
      ),
    );
  }

  Widget _buildLiquidStream(Color color, bool isDark) {
    return Center(
      child: GestureDetector(
        onPanUpdate: _onFlowUpdate,
        onPanStart: (_) => _onFlowStart(),
        onPanEnd: (_) => _onFlowEnd(),
        child: Container(
          width: 0.8.sw, height: 120.h,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(60.r),
            border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Liquid Trace
              Container(
                width: 0.8.sw * _flowProgress,
                height: 80.h,
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.2)]),
                  borderRadius: BorderRadius.circular(40.r),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)],
                ),
              ),
              // Flow Needle
              Positioned(
                left: (0.8.sw * _flowProgress) - 10.w,
                child: Container(
                  width: 40.r, height: 40.r,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: color, blurRadius: 15)]),
                  child: Icon(Icons.blur_on_rounded, color: color, size: 24.r),
                ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowAction(Color color) {
    return Positioned(
      bottom: 80.h,
      child: Column(
        children: [
          Icon(_isFlowing ? Icons.opacity_rounded : Icons.water_drop_rounded, color: color, size: 48.r),
          SizedBox(height: 12.h),
          Text(_isFlowing ? "LIQUID FLOWING..." : "GRAB NEEDLE AND TRACE", style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

