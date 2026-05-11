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

class PrepositionChoiceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PrepositionChoiceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prepositionChoice,
  });

  @override
  State<PrepositionChoiceScreen> createState() => _PrepositionChoiceScreenState();
}

class _PrepositionChoiceScreenState extends State<PrepositionChoiceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  List<Offset> _points = [];
  int _targetNode = -1;
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

  void _onPathEnd(int nodeIndex, int correctIndex) {
    if (_isAnswered) return;
    
    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; _targetNode = nodeIndex; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
        _points = [];
        _targetNode = -1;
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
              _points = [];
              _targetNode = -1;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SPATIAL PRO!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["IN", "ON", "AT", "UNDER"];
        
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
              _buildSentenceBoard(quest.sentenceWithBlank ?? "____ the box.", theme.primaryColor, isDark),
              SizedBox(height: 40.h),
              Expanded(
                child: _buildPathCanvas(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
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
          Icon(Icons.gesture_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("DRAW PATH TO CORRECT PREPOSITION", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSentenceBoard(String template, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Text(template, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 22.sp, color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _buildPathCanvas(List<String> options, int correctIndex, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final startPoint = Offset(constraints.maxWidth / 2, 20.h);
      final nodePoints = [
        Offset(50.w, constraints.maxHeight - 80.h),
        Offset(constraints.maxWidth / 2, constraints.maxHeight - 80.h),
        Offset(constraints.maxWidth - 50.w, constraints.maxHeight - 80.h),
      ];

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          setState(() {
            _points.add(details.localPosition);
            _hapticService.selection();
          });
          // Check collision with nodes
          for (int i = 0; i < nodePoints.length; i++) {
            if ((details.localPosition - nodePoints[i]).distance < 40.r) {
              _onPathEnd(i, correctIndex);
            }
          }
        },
        onPanEnd: (_) => setState(() => _points = []),
        child: CustomPaint(
          size: Size.infinite,
          painter: _PathPainter(points: _points, startPoint: startPoint, nodes: nodePoints, options: options, primaryColor: primaryColor, isAnswered: _isAnswered, targetNode: _targetNode),
        ),
      );
    });
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  final Offset startPoint;
  final List<Offset> nodes;
  final List<String> options;
  final Color primaryColor;
  final bool isAnswered;
  final int targetNode;

  _PathPainter({required this.points, required this.startPoint, required this.nodes, required this.options, required this.primaryColor, required this.isAnswered, required this.targetNode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4.r
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw nodes
    for (int i = 0; i < nodes.length; i++) {
      final isTarget = isAnswered && targetNode == i;
      canvas.drawCircle(nodes[i], 35.r, Paint()..color = (isTarget ? Colors.greenAccent : primaryColor).withValues(alpha: 0.1)..style = PaintingStyle.fill);
      canvas.drawCircle(nodes[i], 35.r, Paint()..color = (isTarget ? Colors.greenAccent : primaryColor)..style = PaintingStyle.stroke..strokeWidth = 2);
      
      final textPainter = TextPainter(
        text: TextSpan(text: options[i % options.length], style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isTarget ? Colors.greenAccent : primaryColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw start socket
    canvas.drawCircle(startPoint, 15.r, Paint()..color = primaryColor..style = PaintingStyle.fill);

    // Draw path
    if (points.isNotEmpty) {
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      for (var p in points) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint..color = primaryColor.withValues(alpha: 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawPath(path, paint..color = Colors.white..maskFilter = null..strokeWidth = 2.r);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

