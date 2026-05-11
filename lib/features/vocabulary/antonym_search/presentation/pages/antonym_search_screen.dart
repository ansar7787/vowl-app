import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

class AntonymSearchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AntonymSearchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.antonymSearch,
  });

  @override
  State<AntonymSearchScreen> createState() => _AntonymSearchScreenState();
}

class _AntonymSearchScreenState extends State<AntonymSearchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _dragOffset = Offset.zero;
  int? _draggingIndex;
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

  void _onDragUpdate(int index, DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _draggingIndex = index;
      _dragOffset += details.delta;
      double distance = _dragOffset.distance;
      if (distance % 20 < 2) _hapticService.selection();
    });
  }

  void _onDragEnd(int index, String selected, String correct) {
    if (_isAnswered) return;
    double distance = _dragOffset.distance;
    
    if (distance > 250.h) {
      bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
      if (isCorrect) {
        _hapticService.success();
        _soundService.playCorrect();
        setState(() { _isAnswered = true; _isCorrect = true; });
        context.read<VocabularyBloc>().add(SubmitAnswer(true));
      } else {
        _hapticService.error();
        _soundService.playWrong();
        setState(() { _isAnswered = true; _isCorrect = false; });
        context.read<VocabularyBloc>().add(SubmitAnswer(false));
      }
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _draggingIndex = null;
      });
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
              _dragOffset = Offset.zero;
              _draggingIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'ANTONYM ACE!', enableDoubleUp: true);
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildElectrode(quest.word ?? "", theme.primaryColor, false),
              ...List.generate(options.length, (i) => _buildOptionPuck(i, options[i], quest.correctAnswer ?? "", theme.primaryColor, isDark)),
              Positioned(top: 20.h, child: _buildInstruction(theme.primaryColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text("STRETCH THE ANTIMATTER BEAM", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
    );
  }

  Widget _buildElectrode(String word, Color color, bool isTop) {
    return Positioned(
      bottom: 100.h,
      child: Container(
        width: 200.w, height: 100.h,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: color, width: 3), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 40)]),
        child: Center(child: Text(word.toUpperCase(), style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 3))),
      ),
    );
  }

  Widget _buildOptionPuck(int index, String text, String correct, Color color, bool isDark) {
    bool isDragging = _draggingIndex == index;
    double distance = isDragging ? _dragOffset.distance : 0;
    
    return Positioned(
      top: 150.h + (isDragging ? _dragOffset.dy : (index * 60.h)),
      left: 100.w + (isDragging ? _dragOffset.dx : 0),
      child: GestureDetector(
        onPanUpdate: (d) => _onDragUpdate(index, d),
        onPanEnd: (d) => _onDragEnd(index, text, correct),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isDragging) _buildElasticBeam(distance, color),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.white, borderRadius: BorderRadius.circular(30.r), border: Border.all(color: isDragging ? color : color.withValues(alpha: 0.2), width: 2), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: Text(text.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 14.sp, color: isDragging ? color : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElasticBeam(double distance, Color color) {
    return CustomPaint(
      size: Size(2.w, distance),
      painter: BeamPainter(distance: distance, color: color),
    );
  }
}

class BeamPainter extends CustomPainter {
  final double distance;
  final Color color;
  BeamPainter({required this.distance, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = (10 - (distance / 40)).clamp(2, 10)..style = PaintingStyle.stroke;
    final path = Path()..moveTo(size.width / 2, 0)..quadraticBezierTo(size.width / 2 + (distance / 10), distance / 2, size.width / 2, distance);
    canvas.drawPath(path, paint);
    // Glow
    paint.strokeWidth = paint.strokeWidth * 2;
    paint.color = color.withValues(alpha: 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

