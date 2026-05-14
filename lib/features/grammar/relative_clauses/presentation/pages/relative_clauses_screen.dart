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

class RelativeClausesScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const RelativeClausesScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.relativeClauses,
  });

  @override
  State<RelativeClausesScreen> createState() => _RelativeClausesScreenState();
}

class _RelativeClausesScreenState extends State<RelativeClausesScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset? _hookPoint;
  int _targetFish = -1;
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

  void _onCatch(int fishIndex, int correctIndex) {
    if (_isAnswered) return;
    
    bool isCorrect = fishIndex == correctIndex;

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; _targetFish = fishIndex; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
        _hookPoint = null;
        _targetFish = -1;
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
              _hookPoint = null;
              _targetFish = -1;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CLAUSE CATCHER!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final fishOptions = quest?.options ?? ["WHO IS SMART", "WHICH IS RED", "THAT I LIKE"];
        
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
              
              // Optimized: Quantum Linker Hub (The Diamond Standard)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: Text(
                    quest.question?.replaceAll('___', '_____') ?? "The data ____",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 20.sp,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

              Expanded(
                child: _buildQuantumArena(fishOptions, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
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
          Icon(Icons.hub_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "ESTABLISH QUANTUM LINK", 
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

  Widget _buildQuantumArena(List<String> nodes, int correctIndex, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final startPoint = Offset(constraints.maxWidth / 2, 40.h); 
      final nodePoints = List.generate(nodes.length, (i) {
        return Offset(
          50.w + (i * (constraints.maxWidth - 100.w) / (nodes.length - 1)),
          constraints.maxHeight - 140.h,
        );
      });

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          setState(() {
            _hookPoint = details.localPosition;
            if (details.localPosition.dy.toInt() % 10 == 0) _hapticService.selection();
          });
          // Check collision with node bubbles
          for (int i = 0; i < nodePoints.length; i++) {
            if ((details.localPosition - nodePoints[i]).distance < 55.r) {
              _onCatch(i, correctIndex);
            }
          }
        },
        onPanEnd: (_) => setState(() => _hookPoint = null),
        child: CustomPaint(
          size: Size.infinite,
          painter: _QuantumPainter(
            hookPoint: _hookPoint, 
            startPoint: startPoint, 
            nodePoints: nodePoints, 
            nodeLabels: nodes, 
            primaryColor: primaryColor, 
            isAnswered: _isAnswered, 
            isCorrect: _isCorrect,
            targetNode: _targetFish,
            isDark: isDark,
          ),
        ),
      );
    });
  }
}

class _QuantumPainter extends CustomPainter {
  final Offset? hookPoint;
  final Offset startPoint;
  final List<Offset> nodePoints;
  final List<String> nodeLabels;
  final Color primaryColor;
  final bool isAnswered;
  final bool? isCorrect;
  final int targetNode;
  final bool isDark;

  _QuantumPainter({
    required this.hookPoint, 
    required this.startPoint, 
    required this.nodePoints, 
    required this.nodeLabels, 
    required this.primaryColor, 
    required this.isAnswered, 
    this.isCorrect,
    required this.targetNode,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..strokeWidth = 3.r
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..style = PaintingStyle.fill;

    // Draw Holographic Node Bubbles
    for (int i = 0; i < nodePoints.length; i++) {
      final isCaught = isAnswered && targetNode == i;
      final isWrong = isAnswered && isCorrect == false && targetNode == i;
      final nodeColor = isCaught 
          ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent) 
          : (isWrong ? Colors.redAccent : primaryColor);
      
      // Outer Plasma Glow
      canvas.drawCircle(
        nodePoints[i], 
        58.r, 
        Paint()..color = nodeColor.withValues(alpha: 0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      );

      // Glass Body
      nodePaint.color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02);
      canvas.drawCircle(nodePoints[i], 52.r, nodePaint);
      
      // Border
      canvas.drawCircle(
        nodePoints[i], 
        52.r, 
        Paint()..color = nodeColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2
      );
      
      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: nodeLabels[i].toUpperCase(), 
          style: GoogleFonts.outfit(
            fontSize: 14.sp, 
            fontWeight: FontWeight.w900, 
            color: isCaught 
                ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent) 
                : (isDark ? Colors.white70 : Colors.black87),
            letterSpacing: 1.5
          )
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 100.w);
      textPainter.paint(canvas, nodePoints[i] - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw Kinetic Data Stream
    if (hookPoint != null || isAnswered) {
      final end = isAnswered && targetNode != -1 ? nodePoints[targetNode] : hookPoint!;
      final path = Path()
        ..moveTo(startPoint.dx, startPoint.dy)
        ..cubicTo(
          startPoint.dx, (startPoint.dy + end.dy) / 2,
          end.dx, (startPoint.dy + end.dy) / 2,
          end.dx, end.dy
        );
      
      final beamColor = isAnswered 
          ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent) 
          : primaryColor;

      // Neon Data Glow
      canvas.drawPath(
        path, 
        linePaint..color = beamColor.withValues(alpha: 0.2)..strokeWidth = 10.r..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      );
      canvas.drawPath(
        path, 
        linePaint..color = beamColor.withValues(alpha: 0.4)..strokeWidth = 4.r..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      );
      canvas.drawPath(path, linePaint..color = beamColor..strokeWidth = 2.r..maskFilter = null);
      
      // Terminals
      canvas.drawCircle(startPoint, 8.r, Paint()..color = primaryColor);
      canvas.drawCircle(end, 10.r, Paint()..color = beamColor);
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumPainter oldDelegate) => 
    oldDelegate.hookPoint != hookPoint || 
    oldDelegate.isAnswered != isAnswered || 
    oldDelegate.isCorrect != isCorrect ||
    oldDelegate.targetNode != targetNode;
}

