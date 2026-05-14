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
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class FixTheSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FixTheSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.fixTheSentence,
  });

  @override
  State<FixTheSentenceScreen> createState() => _FixTheSentenceScreenState();
}

class _FixTheSentenceScreenState extends State<FixTheSentenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final List<Offset> _erasePoints = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int _erasedAmount = 0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onErase(Offset localPosition) {
    if (_isAnswered) return;
    setState(() {
      _erasePoints.add(localPosition);
      _erasedAmount++;
      if (_erasedAmount % 10 == 0) _hapticService.selection();
    });
    
    if (_erasedAmount > 100) {
      _hapticService.success();
      // Auto-fix for demo, normally would show options
    }
  }

  void _submitAnswer(String correct) {
    if (_isAnswered || _erasedAmount < 50) return;
    
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<WritingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
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
              _erasePoints.clear();
              _erasedAmount = 0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX SURGEON!', enableDoubleUp: true);
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
              SizedBox(height: 48.h),
              Expanded(
                child: _buildDigitalBlackboard(quest.passage ?? "", theme.primaryColor),
              ),
              if (!_isAnswered)
                ScaleButton(
                  onTap: () => _submitAnswer(quest.correctAnswer ?? ""),
                  child: Container(
                    width: double.infinity, height: 60.h,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: _erasedAmount > 50 ? theme.primaryColor : Colors.grey, boxShadow: [if (_erasedAmount > 50) BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)]),
                    child: Center(child: Text("VERIFY RESTORATION", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                  ),
                ),
              SizedBox(height: 20.h),
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
          Icon(Icons.auto_fix_normal_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SCRUB AWAY THE LOGICAL DECAY", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDigitalBlackboard(String text, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10, width: 4),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 40)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: GestureDetector(
          onPanUpdate: (details) => _onErase(details.localPosition),
          child: CustomPaint(
            painter: EraserPainter(points: _erasePoints, text: text, color: color, isCorrected: _isAnswered),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class EraserPainter extends CustomPainter {
  final List<Offset> points;
  final String text;
  final Color color;
  final bool isCorrected;
  EraserPainter({required this.points, required this.text, required this.color, required this.isCorrected});
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: GoogleFonts.shareTechMono(fontSize: 24.sp, color: isCorrected ? Colors.greenAccent : Colors.redAccent.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width - 40);
    textPainter.paint(canvas, Offset(20, size.height / 2 - textPainter.height / 2));

    // Draw erasure paths
    final paint = Paint()..color = Colors.black..strokeWidth = 30..strokeCap = StrokeCap.round..blendMode = BlendMode.clear;
    if (!isCorrected) {
      for (var point in points) {
        canvas.drawCircle(point, 20.r, paint);
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

