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
import 'package:flutter_animate/flutter_animate.dart';

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
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
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
                  child: Text(
                    quest.sentence ?? "The antecedent is missing from the gravity field.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 18.sp, 
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

              Expanded(
                child: _buildGravityWell(options, quest.correctAnswerIndex ?? 0, quest.targetWord ?? "it", theme.primaryColor, isDark),
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
          Icon(Icons.gps_fixed_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "ALIGN THE GRAVITY WELL", 
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

  Widget _buildGravityWell(List<String> options, int correctIndex, String pronoun, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final centerPoint = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2 + 20.h);
      final nodeCount = options.length;
      
      // Calculate Orbital Points
      final nodePoints = List.generate(nodeCount, (i) {
        final angle = (i * (2 * pi / nodeCount)) - (pi / 2);
        return Offset(
          centerPoint.dx + cos(angle) * 130.r,
          centerPoint.dy + sin(angle) * 130.r,
        );
      });

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          final localPos = details.localPosition;
          setState(() {
            _rotation = atan2(localPos.dy - centerPoint.dy, localPos.dx - centerPoint.dx);
          });
          // Check collision with nodes
          for (int i = 0; i < nodePoints.length; i++) {
            final nodeAngle = atan2(nodePoints[i].dy - centerPoint.dy, nodePoints[i].dx - centerPoint.dx);
            if ((_rotation - nodeAngle).abs() < 0.15) {
              _onFire(i, correctIndex);
            }
          }
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: _GravityPainter(
            rotation: _rotation, 
            centerPoint: centerPoint, 
            nodes: nodePoints, 
            options: options, 
            primaryColor: primaryColor, 
            isAnswered: _isAnswered, 
            isCorrect: _isCorrect ?? false,
            targetNode: _targetIndex, 
            pronoun: pronoun,
            isDark: isDark
          ),
        ),
      );
    });
  }
}

class _GravityPainter extends CustomPainter {
  final double rotation;
  final Offset centerPoint;
  final List<Offset> nodes;
  final List<String> options;
  final Color primaryColor;
  final bool isAnswered;
  final bool isCorrect;
  final int targetNode;
  final String pronoun;
  final bool isDark;

  _GravityPainter({
    required this.rotation, 
    required this.centerPoint, 
    required this.nodes, 
    required this.options, 
    required this.primaryColor, 
    required this.isAnswered, 
    required this.isCorrect,
    required this.targetNode, 
    required this.pronoun, 
    required this.isDark
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Orbital Rings
    canvas.drawCircle(
      centerPoint, 130.r, 
      Paint()..color = primaryColor.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 1.5.r
    );

    // Draw Antecedents (Orbiting Satellites)
    for (int i = 0; i < nodes.length; i++) {
      final isHit = isAnswered && targetNode == i;
      final isWrong = isAnswered && !isCorrect && targetNode == i;
      final nodeColor = isHit ? Colors.greenAccent : (isWrong ? Colors.redAccent : primaryColor);
      
      // Node Container (Glass Morph)
      final rect = Rect.fromCenter(center: nodes[i], width: 110.w, height: 45.h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(12.r)), 
        Paint()..color = nodeColor.withValues(alpha: 0.1)..style = PaintingStyle.fill
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(12.r)), 
        Paint()..color = nodeColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1
      );
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i].toUpperCase(), 
          style: GoogleFonts.outfit(
            fontSize: 14.sp, 
            fontWeight: FontWeight.bold, 
            color: isHit ? Colors.greenAccent : (isWrong ? Colors.redAccent : (isDark ? Colors.white : Colors.black87))
          )
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw Focal Beam
    if (!isAnswered || targetNode != -1) {
      final beamColor = isAnswered ? (isCorrect ? Colors.greenAccent : Colors.redAccent) : primaryColor;
      
      final beamPaint = Paint()
        ..color = beamColor.withValues(alpha: 0.3)
        ..strokeWidth = 12.r
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        
      final beamCore = Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 2.r;
      
      final beamEnd = isAnswered ? nodes[targetNode] : Offset(centerPoint.dx + cos(rotation) * 160.r, centerPoint.dy + sin(rotation) * 160.r);
      canvas.drawLine(centerPoint, beamEnd, beamPaint);
      canvas.drawLine(centerPoint, beamEnd, beamCore);
    }

    // Draw Gravity Core (The Pronoun)
    final coreColor = isAnswered ? (isCorrect ? Colors.greenAccent : Colors.redAccent) : primaryColor;
    canvas.drawCircle(
      centerPoint, 40.r, 
      Paint()..color = coreColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
    );
    canvas.drawCircle(centerPoint, 35.r, Paint()..color = coreColor);
    
    final pronounPainter = TextPainter(
      text: TextSpan(
        text: pronoun.toUpperCase(), 
        style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white)
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pronounPainter.paint(canvas, centerPoint - Offset(pronounPainter.width / 2, pronounPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GravityPainter oldDelegate) => 
    oldDelegate.rotation != rotation || 
    oldDelegate.isAnswered != isAnswered || 
    oldDelegate.targetNode != targetNode;
}

