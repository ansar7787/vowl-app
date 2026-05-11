import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

import 'package:flutter_animate/flutter_animate.dart';

class WordLinkingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordLinkingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordLinking,
  });

  @override
  State<WordLinkingScreen> createState() => _WordLinkingScreenState();
}

class _WordLinkingScreenState extends State<WordLinkingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Offset _dragPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onTraceUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _dragPosition += details.delta;
    });
  }

  void _onTraceRelease(List<String> words, String correctPair) {
    if (_isAnswered) return;
    
    // Check collision with gaps
    int? collisionIndex;
    for (int i = 0; i < words.length - 1; i++) {
       double xPos = (i + 1) * (1.sw / words.length);
       if ((_dragPosition.dx - xPos).abs() < 40.w && (_dragPosition.dy - 350.h).abs() < 100.h) {
          collisionIndex = i;
          break;
       }
    }

    if (collisionIndex != null) {
      _submitAnswer(collisionIndex, correctPair, words);
    } else {
      setState(() {
        _dragPosition = Offset.zero;
      });
    }
  }

  void _submitAnswer(int gapIndex, String correctPair, List<String> words) {
    if (_isAnswered) return;
    
    String selectedPair = "${words[gapIndex]} ${words[gapIndex+1]}";
    bool isCorrect = selectedPair.toLowerCase().trim() == correctPair.toLowerCase().trim();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
               _isCorrect = null;
              _dragPosition = Offset.zero;
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'LINKAGE MASTER!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is AccentLoaded) ? state.currentQuest : null;
        final words = quest?.words ?? [];

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildLinkingTrigger(quest.textToSpeak ?? "", theme.primaryColor),
              _buildIndustrialField(words, quest.correctAnswer ?? "", theme.primaryColor, isDark),
              if (!_isAnswered) _buildTraceLayer(words, quest.correctAnswer ?? ""),
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
        child: Text("TRACE A PLASMA LINK BETWEEN WORDS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildLinkingTrigger(String text, Color color) {
    return Positioned(
      top: 80.h,
      child: Icon(Icons.bolt_rounded, size: 50.r, color: color).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
    );
  }

  Widget _buildIndustrialField(List<String> words, String correctPair, Color color, bool isDark) {
    return Positioned(
      top: 300.h,
      child: SizedBox(
        width: 1.sw, height: 150.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Connecting Arc
            if (_dragPosition != Offset.zero)
              CustomPaint(
                size: Size(1.sw, 150.h),
                painter: _PlasmaArcPainter(_dragPosition, color),
              ),
            
            // Terminals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: words.map((w) => _buildTerminal(w, color, isDark)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminal(String word, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Text(word.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildTraceLayer(List<String> words, String correctPair) {
    return GestureDetector(
      onPanUpdate: _onTraceUpdate,
      onPanEnd: (_) => _onTraceRelease(words, correctPair),
      child: Container(color: Colors.transparent, width: 1.sw, height: 1.sh),
    );
  }
}

class _PlasmaArcPainter extends CustomPainter {
  final Offset end;
  final Color color;
  _PlasmaArcPainter(this.end, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    path.moveTo(size.width / 2, size.height / 2);
    path.quadraticBezierTo(end.dx, end.dy - 50, end.dx, end.dy);
    
    canvas.drawPath(path, paint);
    canvas.drawCircle(end, 5, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

