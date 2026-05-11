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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

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
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
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
              SizedBox(height: 20.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildConditionBlock(quest.question ?? "IF STATEMENT", theme.primaryColor, isDark),
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
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("LINK THE CHAIN TO THE CORRECT RESULT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildConditionBlock(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(20.r),
      color: Colors.grey[900]?.withValues(alpha: 0.9),
      borderColor: primaryColor.withValues(alpha: 0.5),
      child: Column(
        children: [
          Text("IF", style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: primaryColor)),
          SizedBox(height: 8.h),
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChainArena(List<String> options, int correctIndex, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final startPoint = Offset(constraints.maxWidth / 2, 0);
      final nodePoints = List.generate(options.length, (i) {
        return Offset(
          40.w + (i * (constraints.maxWidth - 80.w) / (options.length - 1)),
          constraints.maxHeight - 100.h,
        );
      });

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          setState(() {
            _chainPoints.add(details.localPosition);
            _hapticService.selection();
          });
          // Check collision with results
          for (int i = 0; i < nodePoints.length; i++) {
            if ((details.localPosition - nodePoints[i]).distance < 50.r) {
              _onConnect(i, correctIndex);
            }
          }
        },
        onPanEnd: (_) => setState(() => _chainPoints = []),
        child: CustomPaint(
          size: Size.infinite,
          painter: _ChainPainter(points: _chainPoints, startPoint: startPoint, nodes: nodePoints, options: options, primaryColor: primaryColor, isAnswered: _isAnswered, targetNode: _targetIndex),
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
  final int targetNode;

  _ChainPainter({required this.points, required this.startPoint, required this.nodes, required this.options, required this.primaryColor, required this.isAnswered, required this.targetNode});

  @override
  void paint(Canvas canvas, Size size) {
    final chainPaint = Paint()..color = Colors.grey[700]!..strokeWidth = 10.r..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final linkPaint = Paint()..color = Colors.grey[400]!..strokeWidth = 4.r..style = PaintingStyle.stroke;

    // Draw Result Blocks
    for (int i = 0; i < nodes.length; i++) {
      final isHit = isAnswered && targetNode == i;
      final blockPaint = Paint()..color = (isHit ? Colors.greenAccent : Colors.grey[800]!)..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: nodes[i], width: 110.w, height: 60.h), Radius.circular(10.r)), blockPaint);
      
      final textPainter = TextPainter(
        text: TextSpan(text: options[i], style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 100.w);
      textPainter.paint(canvas, nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw Chain
    if (points.isNotEmpty || isAnswered) {
      final end = isAnswered ? nodes[targetNode] : points.last;
      final path = Path()..moveTo(startPoint.dx, startPoint.dy)..lineTo(end.dx, end.dy);
      canvas.drawPath(path, chainPaint);
      
      // Add "link" details along the line
      final dist = (end - startPoint).distance;
      final count = (dist / 15.r).floor();
      for (int j = 0; j < count; j++) {
        final pos = Offset.lerp(startPoint, end, j / count)!;
        canvas.drawCircle(pos, 5.r, linkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

