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
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
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
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 20.h),
              
              // Optimized: Concise Context Card (The Diamond Standard)
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
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.fredoka(
                        fontSize: 20.sp, 
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.5
                      ),
                      children: _buildSentenceWithBlank(
                        quest.sentenceWithBlank ?? quest.question ?? "____ sentence.", 
                        _isAnswered ? options[_targetNode] : null, 
                        theme.primaryColor, 
                        isDark
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

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
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gesture_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "TRACE THE ENERGY PATH", 
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

  List<InlineSpan> _buildSentenceWithBlank(String template, String? selected, Color primaryColor, bool isDark) {
    final parts = template.contains("____") ? template.split("____") : template.split("___");
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected != null ? primaryColor : (isDark ? Colors.white38 : Colors.black38), 
                  width: 2
                )
              )
            ),
            child: Text(
              selected ?? "      ", 
              style: GoogleFonts.outfit(
                fontSize: 22.sp, 
                fontWeight: FontWeight.bold, 
                color: primaryColor
              )
            ),
          ).animate(target: selected != null ? 1 : 0).shimmer(duration: 2.seconds),
        ));
      }
    }
    return spans;
  }

  Widget _buildPathCanvas(List<String> options, int correctIndex, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final startPoint = Offset(constraints.maxWidth / 2, 40.h);
      final List<Offset> nodePoints = [];
      final int count = options.length;
      final double bottomY = constraints.maxHeight - 100.h;
      
      if (count <= 3) {
        nodePoints.addAll([
          Offset(80.w, bottomY),
          Offset(constraints.maxWidth / 2, bottomY),
          Offset(constraints.maxWidth - 80.w, bottomY),
        ].take(count));
      } else {
        nodePoints.addAll([
          Offset(90.w, bottomY - 100.h),
          Offset(constraints.maxWidth - 90.w, bottomY - 100.h),
          Offset(90.w, bottomY),
          Offset(constraints.maxWidth - 90.w, bottomY),
        ]);
      }

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          setState(() {
            _points.add(details.localPosition);
          });
          for (int i = 0; i < nodePoints.length; i++) {
            if ((details.localPosition - nodePoints[i]).distance < 50.r) {
              _onPathEnd(i, correctIndex);
            }
          }
        },
        onPanEnd: (_) => setState(() => _points = []),
        child: CustomPaint(
          size: Size.infinite,
          painter: _PathPainter(
            points: _points, 
            startPoint: startPoint, 
            nodes: nodePoints, 
            options: options, 
            primaryColor: primaryColor, 
            isAnswered: _isAnswered,
            isCorrect: _isCorrect ?? false,
            targetNode: _targetNode,
            isDark: isDark
          ),
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
  final bool isCorrect;
  final int targetNode;
  final bool isDark;

  _PathPainter({
    required this.points, 
    required this.startPoint, 
    required this.nodes, 
    required this.options, 
    required this.primaryColor, 
    required this.isAnswered, 
    required this.isCorrect,
    required this.targetNode, 
    required this.isDark
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Nodes (Holographic Power Cells)
    for (int i = 0; i < nodes.length; i++) {
      final isTarget = isAnswered && targetNode == i;
      final nodeColor = isTarget ? Colors.greenAccent : primaryColor;
      
      // Node Aura
      canvas.drawCircle(
        nodes[i], 45.r, 
        Paint()..color = nodeColor.withValues(alpha: 0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      );
      
      // Node Ring
      canvas.drawCircle(
        nodes[i], 40.r, 
        Paint()..color = nodeColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2
      );
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i % options.length], 
          style: GoogleFonts.outfit(
            fontSize: 16.sp, 
            fontWeight: FontWeight.w900, 
            color: isTarget ? Colors.greenAccent : (isDark ? Colors.white : Colors.black87)
          )
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw Socket
    canvas.drawCircle(
      startPoint, 18.r, 
      Paint()..color = primaryColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
    );
    canvas.drawCircle(startPoint, 8.r, Paint()..color = Colors.white);

    // Draw Energy Path (Cinematic Laser)
    if (points.isNotEmpty || isAnswered) {
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      if (isAnswered && targetNode != -1) {
        path.lineTo(nodes[targetNode].dx, nodes[targetNode].dy);
      } else {
        for (var p in points) {
          path.lineTo(p.dx, p.dy);
        }
      }
      
      final pathColor = isAnswered ? (isCorrect ? Colors.greenAccent : Colors.redAccent) : primaryColor;

      // Outer Glow
      canvas.drawPath(
        path, 
        Paint()..color = pathColor.withValues(alpha: 0.4)..strokeWidth = 10.r..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      );
      
      // Inner Glow
      canvas.drawPath(
        path, 
        Paint()..color = pathColor..strokeWidth = 4.r..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      );
      
      // Core Beam
      canvas.drawPath(
        path, 
        Paint()..color = Colors.white..strokeWidth = 1.5.r..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => 
    oldDelegate.points.length != points.length || 
    oldDelegate.isAnswered != isAnswered || 
    oldDelegate.targetNode != targetNode;
}

