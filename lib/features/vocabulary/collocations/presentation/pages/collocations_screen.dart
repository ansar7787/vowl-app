import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

class CollocationsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CollocationsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.collocations,
  });

  @override
  State<CollocationsScreen> createState() => _CollocationsScreenState();
}

class _CollocationsScreenState extends State<CollocationsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _dragPosition = Offset.zero;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onTraceUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _dragPosition += details.delta;
    });
  }

  void _onTraceRelease(List<String> options, String correct) {
    if (_isAnswered) return;
    
    // Check collision with stars
    int? collisionIndex;
    for (int i = 0; i < options.length; i++) {
       double angle = (i * (2 * math.pi / options.length));
       double radius = 140.r;
       Offset starPos = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
       if ((_dragPosition - starPos).distance < 50.r) {
         collisionIndex = i;
         break;
       }
    }

    if (collisionIndex != null) {
      _hapticService.success();
      _submitChoice(options[collisionIndex], correct);
    } else {
      setState(() {
        _dragPosition = Offset.zero;
      });
    }
  }

  void _submitChoice(String selected, String correct) {
    if (_isAnswered) return;
    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    
    if (isCorrect) {
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final livesChanged = state.livesRemaining > (_lastLives ?? 3);
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _dragPosition = Offset.zero;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CHAIN LINKER!', enableDoubleUp: true);
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];
        final word = quest?.word ?? "???";

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildStarMap(word, options, theme.primaryColor, isDark),
              if (!_isAnswered) _buildTracingLayer(options, quest.correctAnswer ?? ""),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Positioned(
      top: 20.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Text("TRACE A PATH TO ALIGN THE CONSTELLATION", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildStarMap(String word, List<String> options, Color color, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Connecting Line
        if (_dragPosition != Offset.zero)
          CustomPaint(
            size: Size(1.sw, 1.sh),
            painter: _StarBeamPainter(_dragPosition, color),
          ),
        
        // Alpha Star
        _buildAlphaStar(word, color, isDark),
        
        // Choice Stars
        ...List.generate(options.length, (i) => _buildChoiceStar(i, options.length, options[i], color, isDark)),
      ],
    );
  }

  Widget _buildAlphaStar(String word, Color color, bool isDark) {
    return Container(
      width: 140.r, height: 140.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)],
      ),
      child: Center(
        child: Text(word.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 2.seconds);
  }

  Widget _buildChoiceStar(int index, int total, String text, Color color, bool isDark) {
    double angle = (index * (2 * math.pi / total));
    final x = 150.w * math.cos(angle);
    final y = 150.w * math.sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Text(text.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color)),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: (2 + index).seconds);
  }

  Widget _buildTracingLayer(List<String> options, String correct) {
    return GestureDetector(
      onPanUpdate: _onTraceUpdate,
      onPanEnd: (_) => _onTraceRelease(options, correct),
      child: Container(color: Colors.transparent, width: 1.sw, height: 1.sh),
    );
  }
}

class _StarBeamPainter extends CustomPainter {
  final Offset end;
  final Color color;
  _StarBeamPainter(this.end, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(Offset.zero, end, paint);
    canvas.drawCircle(end, 6, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

