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

class SpeedVarianceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeedVarianceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speedVariance,
  });

  @override
  State<SpeedVarianceScreen> createState() => _SpeedVarianceScreenState();
}

class _SpeedVarianceScreenState extends State<SpeedVarianceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isScrubbing = false;
  double _dialRotation = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onDialRotate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _isScrubbing = true;
      _dialRotation += details.delta.dx / 100.0;
    });
    _hapticService.selection();
  }

  void _onDialRelease() {
    if (_isAnswered) return;
    setState(() => _isScrubbing = false);
    _submitAnswer();
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
              _isScrubbing = false;
              _dialRotation = 0.0;
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'TEMPO ACE!', enableDoubleUp: true);
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
              _buildSentenceDisplay(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              _buildTempoDial(quest.targetSpeed ?? 1.0, theme.primaryColor, isDark),
              _buildScrubAction(theme.primaryColor),
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
        child: Text("ROTATE THE DIAL TO MATCH THE TARGET SPEED", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSentenceDisplay(String text, Color color, bool isDark) {
    return Positioned(
      top: 80.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: () => _soundService.playTts(text),
            child: Icon(Icons.speed_rounded, color: color, size: 40.r),
          ),
          SizedBox(height: 12.h),
          SizedBox(
             width: 0.8.sw,
             child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87))
          ),
        ],
      ),
    );
  }

  Widget _buildTempoDial(double target, Color color, bool isDark) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Ring
          Container(
            width: 250.r, height: 250.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.black45 : Colors.white12,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 10),
            ),
          ),
          // Target Zone
          CustomPaint(
            size: Size(250.r, 250.r),
            painter: _TargetZonePainter(target, color.withValues(alpha: 0.4)),
          ),
          // Physical Dial
          GestureDetector(
            onPanUpdate: _onDialRotate,
            onPanEnd: (_) => _onDialRelease(),
            child: Transform.rotate(
              angle: _dialRotation,
              child: Container(
                width: 180.r, height: 180.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [isDark ? Colors.grey.shade800 : Colors.grey.shade200, isDark ? Colors.black : Colors.grey.shade400]),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(5, 5))],
                ),
                child: Center(
                  child: Container(
                    width: 10.r, height: 80.r,
                    margin: EdgeInsets.only(bottom: 80.r),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5.r)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrubAction(Color color) {
    return Positioned(
      bottom: 80.h,
      child: Column(
        children: [
          Icon(_isScrubbing ? Icons.mic_rounded : Icons.mic_none_rounded, color: color, size: 48.r)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
          SizedBox(height: 12.h),
          Text(_isScrubbing ? "MAINTAINING SPEED..." : "GRAB DIAL AND SPEAK", style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _TargetZonePainter extends CustomPainter {
  final double target;
  final Color color;
  _TargetZonePainter(this.target, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    double startAngle = -math.pi / 2 + (target * 0.5);
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), startAngle, 0.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
