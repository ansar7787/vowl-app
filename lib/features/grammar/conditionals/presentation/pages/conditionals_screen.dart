import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConditionalsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConditionalsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conditionals,
  });

  @override
  State<ConditionalsScreen> createState() => _ConditionalsScreenState();
}

class _ConditionalsScreenState extends State<ConditionalsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  List<Offset> _chainPoints = [];
  int _targetIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onConnect(int nodeIndex, int correctIndex) {
    if (_isAnswered) return;
    
    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; _targetIndex = nodeIndex; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
        _chainPoints = [];
        _targetIndex = -1;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _chainPoints = [];
              _targetIndex = -1;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'LOGIC LORD!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["RESULT A", "RESULT B", "RESULT C"];
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 20.h),
              
              // Optimized: Concise Context Card (The Diamond Standard)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "IF CONDITION", 
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp, 
                          fontWeight: FontWeight.w900, 
                          color: theme.primaryColor,
                          letterSpacing: 2
                        )
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        quest.question ?? "",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 20.sp,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

              Expanded(
                child: _buildChainArena(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              ),
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
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "FUSE THE CONSEQUENCE", 
            style: GoogleFonts.outfit(
              fontSize: 10.sp, 
              fontWeight: FontWeight.w900, 
              color: primaryColor, 
              letterSpacing: 1.5
            )
          ),
        ],
      ),
    );
  }

  Widget _buildChainArena(List<String> options, int correctIndex, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final startPoint = Offset(constraints.maxWidth / 2, 20.h);
      final nodePoints = List.generate(options.length, (i) {
        return Offset(
          constraints.maxWidth / 2,
          100.h + (i * (constraints.maxHeight - 160.h) / (options.length - 1)),
        );
      });

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          setState(() {
            _chainPoints.add(details.localPosition);
            _hapticService.selection();
          });
          // Check collision with Logic Terminals
          for (int i = 0; i < nodePoints.length; i++) {
            if ((details.localPosition - nodePoints[i]).distance < 60.r) {
              _onConnect(i, correctIndex);
            }
          }
        },
        onPanEnd: (_) => setState(() => _chainPoints = []),
        child: CustomPaint(
          size: Size.infinite,
          painter: _ChainPainter(
            points: _chainPoints, 
            startPoint: startPoint, 
            nodes: nodePoints, 
            options: options, 
            primaryColor: primaryColor, 
            isAnswered: _isAnswered, 
            isCorrect: _isCorrect,
            targetNode: _targetIndex,
            isDark: isDark,
          ),
        ),
      );
    });
  }
}

class _ChainPainter extends CustomPainter {
  final List<Offset> points;
  final Offset startPoint;
  final List<Offset> nodes;
  final List<String> options;
  final Color primaryColor;
  final bool isAnswered;
  final bool? isCorrect;
  final int targetNode;
  final bool isDark;

  _ChainPainter({
    required this.points, 
    required this.startPoint, 
    required this.nodes, 
    required this.options, 
    required this.primaryColor, 
    required this.isAnswered, 
    this.isCorrect,
    required this.targetNode,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Logic Terminals
    for (int i = 0; i < nodes.length; i++) {
      final isHit = isAnswered && targetNode == i;
      final isWrong = isAnswered && isCorrect == false && targetNode == i;
      final blockColor = isHit 
          ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent) 
          : (isWrong ? Colors.redAccent : primaryColor);
      
      // Terminal Glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: nodes[i], width: 280.w, height: 65.h), Radius.circular(20.r)),
        Paint()..color = blockColor.withValues(alpha: 0.05)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      );

      // Terminal Body
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: nodes[i], width: 260.w, height: 60.h), Radius.circular(16.r)),
        Paint()..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)
      );
      
      // Terminal Border
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: nodes[i], width: 260.w, height: 60.h), Radius.circular(16.r)),
        Paint()..color = blockColor.withValues(alpha: (isHit || isWrong) ? 0.6 : 0.2)..style = PaintingStyle.stroke..strokeWidth = 2
      );
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i], 
          style: GoogleFonts.outfit(
            fontSize: 14.sp, 
            fontWeight: (isHit || isWrong) ? FontWeight.w800 : FontWeight.w600, 
            color: isHit 
                ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent) 
                : (isDark ? Colors.white70 : Colors.black87)
          )
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 240.w);
      textPainter.paint(canvas, nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw Plasma Fusion Arc
    if (points.isNotEmpty || (isAnswered && targetNode != -1)) {
      final end = isAnswered ? nodes[targetNode] : points.last;
      final beamColor = isAnswered 
          ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent) 
          : primaryColor;
          
      final plasmaPaint = Paint()
        ..color = beamColor
        ..strokeWidth = 3.r
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Neon Core
      canvas.drawLine(startPoint, end, plasmaPaint);
      
      // Outer Glow
      canvas.drawLine(
        startPoint, 
        end, 
        plasmaPaint..color = beamColor.withValues(alpha: 0.3)..strokeWidth = 8.r..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      );

      // Fusion Sparkles
      final dist = (end - startPoint).distance;
      final count = (dist / 20.r).floor().clamp(2, 50);
      for (int j = 0; j < count; j++) {
        final pos = Offset.lerp(startPoint, end, j / count)!;
        canvas.drawCircle(pos, 2.r, Paint()..color = Colors.white.withValues(alpha: 0.8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChainPainter oldDelegate) => 
    oldDelegate.points.length != points.length || 
    oldDelegate.isAnswered != isAnswered || 
    oldDelegate.isCorrect != isCorrect ||
    oldDelegate.targetNode != targetNode;
}

