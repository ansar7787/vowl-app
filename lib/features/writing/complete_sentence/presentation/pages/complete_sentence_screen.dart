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
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class CompleteSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CompleteSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.completeSentence,
  });

  @override
  State<CompleteSentenceScreen> createState() => _CompleteSentenceScreenState();
}

class _CompleteSentenceScreenState extends State<CompleteSentenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset? _dragStart;
  Offset? _dragCurrent;
  String? _selectedProjectile;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onBridgeStart(Offset globalPosition) {
    if (_isAnswered) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPos = renderBox.globalToLocal(globalPosition);
      setState(() {
        _dragStart = localPos;
        _dragCurrent = localPos;
        _hapticService.selection();
      });
    }
  }

  void _onBridgeUpdate(Offset globalPosition) {
    if (_isAnswered || _dragStart == null) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _dragCurrent = renderBox.globalToLocal(globalPosition);
      });
    }
  }

  void _onFire(String selected, String correct) {
    if (_isAnswered) return;
    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    
    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; _selectedProjectile = selected; });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<WritingBloc>().add(SubmitAnswer(false));
      Future.delayed(1.seconds, () {
        if (mounted) {
          setState(() {
            _dragStart = null;
            _dragCurrent = null;
            _selectedProjectile = null;
            _isAnswered = false;
            _isCorrect = null;
          });
        }
      });
    }
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
              _selectedProjectile = null;
              _dragStart = null;
              _dragCurrent = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'COMPLETION MASTER!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];
        
        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 16.h),
                      _buildInstruction(theme.primaryColor),
                      SizedBox(height: 32.h),
                      
                      _buildTargetWall(quest.partialSentence ?? "", _selectedProjectile, theme.primaryColor, isDark),
                      SizedBox(height: 32.h),
                      
                      _buildBallistaAmmo(options, quest.correctAnswer ?? "", theme.primaryColor, isDark),
                      
                      if (_isAnswered) ...[
                        SizedBox(height: 30.h),
                        _buildCorrectResult(quest, theme.primaryColor, isDark),
                      ],
                      SizedBox(height: 60.h),
                    ],
                  ),
                ),
              ),
              if (_dragStart != null && _dragCurrent != null)
                IgnorePointer(
                  child: CustomPaint(
                    painter: TrajectoryPainter(start: _dragStart!, end: _dragCurrent!, color: theme.primaryColor),
                    size: Size.infinite,
                  ),
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
          Icon(Icons.gps_fixed_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("LAUNCH THE MISSING FRAGMENT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTargetWall(String text, String? injected, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: DragTarget<String>(
              onAcceptWithDetails: (details) => _onFire(details.data, details.data),
              builder: (context, candidateData, rejectedData) {
                return Text(
                  text.replaceAll('____', injected?.toUpperCase() ?? "____"),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 20.sp, 
                    color: injected != null ? color : (isDark ? Colors.white70 : Colors.black87), 
                    fontWeight: FontWeight.bold,
                    height: 1.4
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBallistaAmmo(List<String> options, String correct, Color color, bool isDark) {
    return Wrap(
      spacing: 12.w, runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((o) => GestureDetector(
        onPanStart: (details) => _onBridgeStart(details.globalPosition),
        onPanUpdate: (details) => _onBridgeUpdate(details.globalPosition),
        onPanEnd: (details) => _onFire(o, correct),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.black87 : Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: isDark ? 0.35 : 0.15), blurRadius: 10)
            ],
          ),
          child: Text(
            o.toUpperCase(), 
            style: GoogleFonts.shareTechMono(
              fontSize: 12.sp, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : Colors.black87
            )
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCorrectResult(dynamic quest, Color primaryColor, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: displayColor, size: 36.r),
          SizedBox(height: 10.h),
          Text(
            correct ? "CORRECT!" : "INCORRECT",
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}

class TrajectoryPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  TrajectoryPainter({required this.start, required this.end, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    
    final diff = start - end;
    final controlPoint = Offset(start.dx + diff.dx, start.dy - diff.dy.abs() * 2);
    final targetPoint = Offset(start.dx + diff.dx * 2, start.dy - diff.dy.abs() * 3);
    
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, targetPoint.dx, targetPoint.dy);
    
    canvas.drawPath(path, paint);
    canvas.drawCircle(targetPoint, 8.r, Paint()..color = color.withValues(alpha: 0.5));
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
