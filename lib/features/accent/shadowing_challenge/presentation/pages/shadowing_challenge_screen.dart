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

import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';

class ShadowingChallengeScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ShadowingChallengeScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.shadowingChallenge,
  });

  @override
  State<ShadowingChallengeScreen> createState() => _ShadowingChallengeScreenState();
}

class _ShadowingChallengeScreenState extends State<ShadowingChallengeScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isShadowing = false;
  double _traceProgress = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onTraceUpdate(DragUpdateDetails details) {
    if (_isAnswered || !_isShadowing) return;
    setState(() {
      _traceProgress = (_traceProgress + (details.delta.dx / 1.sw)).clamp(0.0, 1.0);
    });
    _hapticService.selection();
  }

  void _onShadowTap() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _isShadowing = !_isShadowing;
      if (_isShadowing) _traceProgress = 0.0;
    });
    
    if (!_isShadowing) {
      _submitAnswer();
    }
  }

  void _submitAnswer() {
    _hapticService.success();
    _soundService.playCorrect();
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
              _isShadowing = false;
              _traceProgress = 0.0;
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SHADOW GHOST!', enableDoubleUp: true);
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
              _buildStarDustScene(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              _buildObservatoryControls(theme.primaryColor, isDark),
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
        child: Text("TRACE THE STARDUST WAVE WHILE REPEATING", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildStarDustScene(String text, Color color, bool isDark) {
    return Positioned(
      top: 100.h,
      child: Column(
        children: [
          Container(
            width: 0.8.sw,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(20.r)),
            child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white : Colors.black87, height: 1.5)),
          ),
          SizedBox(height: 60.h),
          _buildWaveformTrace(color),
        ],
      ),
    );
  }

  Widget _buildWaveformTrace(Color color) {
    return GestureDetector(
      onPanUpdate: _onTraceUpdate,
      child: Container(
        width: 1.sw, height: 150.h,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Waveform Path
            CustomPaint(
              size: Size(0.9.sw, 100.h),
              painter: _WaveformPainter(color.withValues(alpha: 0.2)),
            ),
            // User Trace
            CustomPaint(
              size: Size(0.9.sw, 100.h),
              painter: _WaveformPainter(color, progress: _traceProgress),
            ),
            // Comet
            Positioned(
              left: 0.05.sw + (_traceProgress * 0.9.sw) - 10.w,
              child: Icon(Icons.auto_awesome_rounded, color: color, size: 24.r)
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 1.seconds)
                  .scale(begin: const Offset(1,1), end: const Offset(1.5, 1.5), duration: 500.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservatoryControls(Color color, bool isDark) {
    return Positioned(
      bottom: 60.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: _onShadowTap,
            child: Container(
              width: 100.r, height: 100.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isShadowing ? color : color.withValues(alpha: 0.1),
                border: Border.all(color: color, width: 3),
                boxShadow: _isShadowing ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)] : [],
              ),
              child: Icon(_isShadowing ? Icons.stop_rounded : Icons.mic_rounded, color: _isShadowing ? Colors.white : color, size: 48.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(_isShadowing ? "TRACE THE WAVE..." : "TAP TO OBSERVE", style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color, letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  final double progress;
  _WaveformPainter(this.color, {this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    double mid = size.height / 2;
    path.moveTo(0, mid);

    for (double i = 0; i <= size.width * progress; i += 5) {
      double y = mid + (math.sin(i / 10.0) * 20.0) + (math.cos(i / 15.0) * 10.0);
      path.lineTo(i, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
