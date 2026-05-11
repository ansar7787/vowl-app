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

class GuessTitleScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GuessTitleScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.guessTitle,
  });

  @override
  State<GuessTitleScreen> createState() => _GuessTitleScreenState();
}

class _GuessTitleScreenState extends State<GuessTitleScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _dragOffset = Offset.zero;
  int? _draggingIndex;
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

  void _onLabelDrag(int index, Offset delta) {
    if (_isAnswered) {
      return;
    }
    setState(() {
      _draggingIndex = index;
      _dragOffset += delta;
      _hapticService.selection();
    });
  }

  void _onLabelEnd(int index, String selected, String correct) {
    if (_isAnswered) {
      return;
    }
    
    // Check if snapped into pocket zone (middle-bottom of screen)
    if (_dragOffset.dy > 150.h && _dragOffset.dx.abs() < 100.w) {
      _submitAnswer(index, selected, correct);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _draggingIndex = null;
      });
    }
  }

  void _submitAnswer(int index, String selected, String correct) {
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
      // Reset after wrong
      Future.delayed(1.seconds, () {
        if (mounted) {
          setState(() {
            _dragOffset = Offset.zero;
            _draggingIndex = null;
          });
        }
      });
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
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _dragOffset = Offset.zero;
              _draggingIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'TITLE EXPERT!', enableDoubleUp: true);
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
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 24.h),
              _buildCargoCrate(quest.passage ?? "", theme.primaryColor, isDark),
              const Spacer(),
              _buildLabelRack(quest.options ?? [], quest.correctAnswer ?? "", theme.primaryColor),
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
          Icon(Icons.inventory_2_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SNAP THE TITLE LABEL ONTO THE CRATE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCargoCrate(String passage, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(passage, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 16.sp, height: 1.5, color: isDark ? Colors.white70 : Colors.black87)),
          SizedBox(height: 32.h),
          // The Pocket
          Container(
            height: 60.h, width: 240.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2, style: BorderStyle.none),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isAnswered)
                  Text( (context.read<ReadingBloc>().state as ReadingLoaded).currentQuest.correctAnswer?.toUpperCase() ?? "", style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: color))
                else
                  Text("INSERT LABEL HERE", style: GoogleFonts.shareTechMono(color: color.withValues(alpha: 0.4), fontSize: 12.sp)),
                
                // Dash border
                CustomPaint(
                  size: Size(240.w, 60.h),
                  painter: DashPainter(color: color.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelRack(List<String> labels, String correct, Color color) {
    return Wrap(
      spacing: 12.w, runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: List.generate(labels.length, (index) {
        bool isDragging = _draggingIndex == index;
        return Transform.translate(
          offset: isDragging ? _dragOffset : Offset.zero,
          child: GestureDetector(
            onPanUpdate: (details) => _onLabelDrag(index, details.delta),
            onPanEnd: (details) => _onLabelEnd(index, labels[index], correct),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: const Offset(2, 2))],
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(labels[index].toUpperCase(), style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.black87)),
            ),
          ),
        );
      }),
    );
  }
}

class DashPainter extends CustomPainter {
  final Color color;
  DashPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    double dashWidth = 5, dashSpace = 3, startX = 0;
    while (startX < size.width) { canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint); startX += dashWidth + dashSpace; }
    startX = 0; while (startX < size.width) { canvas.drawLine(Offset(startX, size.height), Offset(startX + dashWidth, size.height), paint); startX += dashWidth + dashSpace; }
    double startY = 0; while (startY < size.height) { canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint); startY += dashWidth + dashSpace; }
    startY = 0; while (startY < size.height) { canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint); startY += dashWidth + dashSpace; }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

