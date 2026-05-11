import 'dart:math';
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

class PronounResolutionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PronounResolutionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pronounResolution,
  });

  @override
  State<PronounResolutionScreen> createState() => _PronounResolutionScreenState();
}

class _PronounResolutionScreenState extends State<PronounResolutionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _rotation = 0.0;
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

  void _onFire(int nodeIndex, int correctIndex) {
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
        _rotation = 0.0;
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
              _rotation = 0.0;
              _targetIndex = -1;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'REFERENT EXPERT!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["NOUN A", "NOUN B", "NOUN C"];
        
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
              SizedBox(height: 24.h),
              _buildSentenceBoard(quest.sentence ?? "CONTEXT SENTENCE", theme.primaryColor, isDark),
              Expanded(
                child: _buildLaserArena(options, quest.correctAnswerIndex ?? 0, quest.targetWord ?? "it", theme.primaryColor, isDark),
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
          Icon(Icons.gps_fixed_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("AIM LASER AT THE ANTECEDENT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSentenceBoard(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(16.r),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 16.sp, color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _buildLaserArena(List<String> options, int correctIndex, String pronoun, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final basePoint = Offset(constraints.maxWidth / 2, constraints.maxHeight - 60.h);
      final nodeCount = options.length;
      final nodePoints = List.generate(nodeCount, (i) {
        final angle = (i * (3.14 / (nodeCount - 1))) - 3.14;
        return Offset(
          constraints.maxWidth / 2 + cos(angle) * 150.r,
          basePoint.dy - 200.h + sin(angle) * 50.h,
        );
      });

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          final localPos = details.localPosition;
          setState(() {
            _rotation = atan2(localPos.dy - basePoint.dy, localPos.dx - basePoint.dx);
            _hapticService.selection();
          });
          // Check collision
          for (int i = 0; i < nodePoints.length; i++) {
            final nodeAngle = atan2(nodePoints[i].dy - basePoint.dy, nodePoints[i].dx - basePoint.dx);
            if ((_rotation - nodeAngle).abs() < 0.1) {
              _onFire(i, correctIndex);
            }
          }
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: _LaserPainter(rotation: _rotation, basePoint: basePoint, nodes: nodePoints, options: options, primaryColor: primaryColor, isAnswered: _isAnswered, targetNode: _targetIndex, pronoun: pronoun),
        ),
      );
    });
  }
}

class _LaserPainter extends CustomPainter {
  final double rotation;
  final Offset basePoint;
  final List<Offset> nodes;
  final List<String> options;
  final Color primaryColor;
  final bool isAnswered;
  final int targetNode;
  final String pronoun;

  _LaserPainter({required this.rotation, required this.basePoint, required this.nodes, required this.options, required this.primaryColor, required this.isAnswered, required this.targetNode, required this.pronoun});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Nodes
    for (int i = 0; i < nodes.length; i++) {
      final isHit = isAnswered && targetNode == i;
      final nodePaint = Paint()..color = (isHit ? Colors.greenAccent : primaryColor).withValues(alpha: 0.1)..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: nodes[i], width: 100.w, height: 40.h), Radius.circular(10.r)), nodePaint);
      
      final textPainter = TextPainter(
        text: TextSpan(text: options[i], style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isHit ? Colors.greenAccent : primaryColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw Laser Beam
    if (!isAnswered || targetNode != -1) {
      final beamPaint = Paint()..color = primaryColor..strokeWidth = 6.r..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final beamCore = Paint()..color = Colors.white..strokeWidth = 2.r;
      
      final beamEnd = Offset(basePoint.dx + cos(rotation) * 400.r, basePoint.dy + sin(rotation) * 400.r);
      canvas.drawLine(basePoint, beamEnd, beamPaint);
      canvas.drawLine(basePoint, beamEnd, beamCore);
    }

    // Draw Base
    canvas.drawCircle(basePoint, 30.r, Paint()..color = primaryColor);
    final pronounPainter = TextPainter(
      text: TextSpan(text: pronoun.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    pronounPainter.paint(canvas, basePoint - Offset(pronounPainter.width / 2, pronounPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

