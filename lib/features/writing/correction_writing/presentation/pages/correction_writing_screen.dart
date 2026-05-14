import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CorrectionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CorrectionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.correctionWriting,
  });

  @override
  State<CorrectionWritingScreen> createState() => _CorrectionWritingScreenState();
}

class _CorrectionWritingScreenState extends State<CorrectionWritingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<Offset> _polishPoints = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  double _polishProgress = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onPolish(Offset localPosition) {
    if (_isAnswered) return;
    setState(() {
      _polishPoints.add(localPosition);
      _polishProgress = (_polishPoints.length / 300).clamp(0.0, 1.0);
      if (_polishPoints.length % 10 == 0) _hapticService.selection();
    });
    if (_polishProgress >= 1.0) _submitAnswer();
  }

  void _submitAnswer() {
    if (_isAnswered) return;
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<WritingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _polishPoints.clear();
              _polishProgress = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX AUDITOR!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        
        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildPolishMirror(quest.passage ?? "", quest.correctAnswer ?? "", theme.primaryColor, isDark),
              SizedBox(height: 32.h),
              _buildReflectivityMeter(_polishProgress, theme.primaryColor),
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
          Icon(Icons.auto_fix_high_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("RUB AWAY THE OXIDATION TO REVEAL THE TRUTH", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPolishMirror(String faulty, String correct, Color color, bool isDark) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 5)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25.r),
          child: GestureDetector(
            onPanUpdate: (details) => _onPolish(details.localPosition),
            child: CustomPaint(
              painter: MirrorPainter(points: _polishPoints, faulty: faulty, correct: correct, color: color, progress: _polishProgress, isRevealed: _isAnswered),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReflectivityMeter(double progress, Color color) {
    return Column(
      children: [
        Text("REFLECTIVITY: ${(progress * 100).toInt()}%", style: GoogleFonts.shareTechMono(color: color, fontSize: 12.sp, letterSpacing: 2)),
        SizedBox(height: 12.h),
        Container(
          width: 200.w, height: 6.h,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3.r)),
          child: Align(alignment: Alignment.centerLeft, child: Container(width: 200.w * progress, color: color).animate(target: progress).shimmer()),
        ),
      ],
    );
  }
}

class MirrorPainter extends CustomPainter {
  final List<Offset> points;
  final String faulty;
  final String correct;
  final Color color;
  final double progress;
  final bool isRevealed;
  MirrorPainter({required this.points, required this.faulty, required this.correct, required this.color, required this.progress, required this.isRevealed});
  @override
  void paint(Canvas canvas, Size size) {
    // Draw Background (Polished Surface)
    final bgPaint = Paint()..color = const Color(0xFF121212);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw Correct Text (underneath)
    final correctPainter = TextPainter(
      text: TextSpan(text: correct, style: GoogleFonts.spectral(fontSize: 18.sp, color: color.withValues(alpha: isRevealed ? 1.0 : progress), height: 1.6)),
      textAlign: TextAlign.center, textDirection: TextDirection.ltr,
    );
    correctPainter.layout(maxWidth: size.width - 60);
    correctPainter.paint(canvas, Offset(30, size.height / 2 - correctPainter.height / 2));

    // Draw Oxidation Layer
    if (!isRevealed) {
      canvas.saveLayer(Offset.zero & size, Paint());
      
      // Tarnished surface
      final rustPaint = Paint()..color = Colors.grey.shade900;
      canvas.drawRect(Offset.zero & size, rustPaint);

      // Faulty Text (on top of rust)
      final faultyPainter = TextPainter(
        text: TextSpan(text: faulty, style: GoogleFonts.spectral(fontSize: 18.sp, color: Colors.grey.shade700, height: 1.6)),
        textAlign: TextAlign.center, textDirection: TextDirection.ltr,
      );
      faultyPainter.layout(maxWidth: size.width - 60);
      faultyPainter.paint(canvas, Offset(30, size.height / 2 - faultyPainter.height / 2));

      // Eraser/Polish paths
      final polishPaint = Paint()..color = Colors.black..strokeWidth = 60..strokeCap = StrokeCap.round..blendMode = BlendMode.clear;
      for (var point in points) {
        canvas.drawCircle(point, 30.r, polishPaint);
      }
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

