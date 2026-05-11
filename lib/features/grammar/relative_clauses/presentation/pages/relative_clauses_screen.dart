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
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
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
              SizedBox(height: 20.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildSentenceDeck(quest.sentence ?? "The boy", theme.primaryColor, isDark),
              Expanded(
                child: _buildFishingArena(fishOptions, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
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
          Icon(Icons.phishing_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("CAST HOOK TO CATCH CORRECT CLAUSE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSentenceDeck(String sentence, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(sentence, style: GoogleFonts.fredoka(fontSize: 22.sp, color: isDark ? Colors.white70 : Colors.black87)),
          SizedBox(width: 10.w),
          Container(
            width: 40.w, height: 4.h,
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2.r)),
          ),
        ],
      ),
    );
  }

  Widget _buildFishingArena(List<String> fish, int correctIndex, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final startPoint = Offset(constraints.maxWidth / 2 + 50.w, 0); // Aligned with the sentence gap
      final fishPoints = List.generate(fish.length, (i) {
        return Offset(
          40.w + (i * (constraints.maxWidth - 80.w) / (fish.length - 1)),
          constraints.maxHeight - 100.h,
        );
      });

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          setState(() {
            _hookPoint = details.localPosition;
            _hapticService.selection();
          });
          // Check collision with fish
          for (int i = 0; i < fishPoints.length; i++) {
            if ((details.localPosition - fishPoints[i]).distance < 40.r) {
              _onCatch(i, correctIndex);
            }
          }
        },
        onPanEnd: (_) => setState(() => _hookPoint = null),
        child: CustomPaint(
          size: Size.infinite,
          painter: _FishingPainter(hookPoint: _hookPoint, startPoint: startPoint, fishPoints: fishPoints, fishLabels: fish, primaryColor: primaryColor, isAnswered: _isAnswered, targetFish: _targetFish),
        ),
      );
    });
  }
}

class _FishingPainter extends CustomPainter {
  final Offset? hookPoint;
  final Offset startPoint;
  final List<Offset> fishPoints;
  final List<String> fishLabels;
  final Color primaryColor;
  final bool isAnswered;
  final int targetFish;

  _FishingPainter({required this.hookPoint, required this.startPoint, required this.fishPoints, required this.fishLabels, required this.primaryColor, required this.isAnswered, required this.targetFish});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = primaryColor..strokeWidth = 2.r..style = PaintingStyle.stroke;
    final fishPaint = Paint()..style = PaintingStyle.fill;

    // Draw Fish
    for (int i = 0; i < fishPoints.length; i++) {
      final isCaught = isAnswered && targetFish == i;
      fishPaint.color = (isCaught ? Colors.greenAccent : primaryColor).withValues(alpha: 0.1);
      canvas.drawCircle(fishPoints[i], 45.r, fishPaint);
      canvas.drawCircle(fishPoints[i], 45.r, Paint()..color = (isCaught ? Colors.greenAccent : primaryColor)..style = PaintingStyle.stroke..strokeWidth = 2);
      
      final textPainter = TextPainter(
        text: TextSpan(text: fishLabels[i], style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: isCaught ? Colors.greenAccent : primaryColor)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80.w);
      textPainter.paint(canvas, fishPoints[i] - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw Line
    if (hookPoint != null || isAnswered) {
      final end = isAnswered ? fishPoints[targetFish] : hookPoint!;
      final path = Path()..moveTo(startPoint.dx, startPoint.dy)..quadraticBezierTo(startPoint.dx, (startPoint.dy + end.dy) / 2, end.dx, end.dy);
      canvas.drawPath(path, linePaint..strokeWidth = 3.r..color = primaryColor.withValues(alpha: 0.5));
      canvas.drawCircle(end, 8.r, Paint()..color = primaryColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

