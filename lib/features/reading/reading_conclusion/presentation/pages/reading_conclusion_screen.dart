import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReadingConclusionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingConclusionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingConclusion,
  });

  @override
  State<ReadingConclusionScreen> createState() => _ReadingConclusionScreenState();
}

class _ReadingConclusionScreenState extends State<ReadingConclusionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset? _dragStart;
  Offset? _dragCurrent;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(FetchReadingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onBridgeStart(Offset position) {
    if (_isAnswered) return;
    setState(() {
      _dragStart = position;
      _dragCurrent = position;
      _hapticService.selection();
    });
  }

  void _onBridgeUpdate(Offset delta) {
    if (_isAnswered || _dragStart == null) return;
    setState(() {
      _dragCurrent = (_dragCurrent ?? Offset.zero) + delta;
    });
  }

  void _onBridgeEnd(int index, String selected, String correct) {
    if (_isAnswered) return;
    _submitAnswer(index, selected, correct);
  }

  void _submitAnswer(int index, String selected, String correct) {
    setState(() => _selectedIndex = index);
    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<ReadingBloc>().add(SubmitAnswer(false));
      Future.delayed(1.seconds, () => setState(() {
        _dragStart = null;
        _dragCurrent = null;
        _selectedIndex = null;
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _dragStart = null;
              _dragCurrent = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'FINAL VERDICT DELIVERED!', enableDoubleUp: true);
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ReadingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ReadingLoaded) ? state.currentQuest : null;
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildInstruction(theme.primaryColor),
                  SizedBox(height: 48.h),
                  _buildCentralPassage(quest.passage ?? "", theme.primaryColor, isDark),
                  const Spacer(),
                  _buildConclusionTerminals(quest.options ?? [], quest.correctAnswer ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 40.h),
                ],
              ),
              if (_dragStart != null && _dragCurrent != null)
                CustomPaint(
                  painter: BridgePainter(start: _dragStart!, end: _dragCurrent!, color: theme.primaryColor),
                  size: Size.infinite,
                ),
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
          Icon(Icons.hub_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("BRIDGE THE PASSAGE TO THE CORRECT VERDICT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCentralPassage(String text, Color color, bool isDark) {
    return GestureDetector(
      onPanStart: (details) => _onBridgeStart(details.globalPosition),
      onPanUpdate: (details) => _onBridgeUpdate(details.delta),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30)],
        ),
        child: Column(
          children: [
            Icon(Icons.auto_awesome_motion_rounded, color: color, size: 32.r),
            SizedBox(height: 16.h),
            Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 16.sp, height: 1.5, color: Colors.white70)),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds),
    );
  }

  Widget _buildConclusionTerminals(List<String> options, String correct, Color color, bool isDark) {
    return Column(
      children: List.generate(options.length, (index) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: DragTarget<String>(
          onAcceptWithDetails: (details) => _onBridgeEnd(index, options[index], correct),
          builder: (context, candidateData, rejectedData) {
            bool isSelected = _selectedIndex == index;
            bool isCorrect = _isAnswered && options[index].trim().toLowerCase() == correct.trim().toLowerCase();
            bool isWrong = _isAnswered && isSelected && !isCorrect;

            return AnimatedContainer(
              duration: 300.milliseconds,
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.greenAccent.withValues(alpha: 0.2) : (isWrong ? Colors.redAccent.withValues(alpha: 0.2) : (isSelected ? color.withValues(alpha: 0.2) : Colors.white10)),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: isCorrect || isWrong || isSelected ? (isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : color)) : Colors.white24, width: 2),
              ),
              child: Text(options[index].toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            );
          },
        ),
      )),
    );
  }
}

class BridgePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  BridgePainter({required this.start, required this.end, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke;
    final glow = Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 10..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 + 50, end.dx, end.dy);
    
    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
    
    // Draw crystal joints
    canvas.drawCircle(start, 5.r, Paint()..color = color);
    canvas.drawCircle(end, 5.r, Paint()..color = color);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

