import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DailyJournalScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DailyJournalScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dailyJournal,
  });

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _controller = TextEditingController();
  
  final List<Offset> _revealPoints = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
    _controller.addListener(() {
      setState(() {}); // Trigger repaint to reveal text
    });
  }

  void _onReveal(Offset localPosition) {
    if (_isAnswered) return;
    setState(() {
      _revealPoints.add(localPosition);
      if (_revealPoints.length % 5 == 0) _hapticService.selection();
    });
  }

  void _submitAnswer() {
    if (_isAnswered || _controller.text.isEmpty) return;
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<WritingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _controller.clear();
              _revealPoints.clear();
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'REFLECTIVE MASTER!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        
        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildJournalPrompt(quest.prompt ?? "", theme.primaryColor, isDark),
              SizedBox(height: 32.h),
              Expanded(
                child: _buildScratchArea(_controller.text, theme.primaryColor, isDark),
              ),
              SizedBox(height: 20.h),
              _buildHiddenInput(theme.primaryColor),
              SizedBox(height: 32.h),
              if (!_isAnswered)
                ScaleButton(
                  onTap: _submitAnswer,
                  child: Container(
                    width: double.infinity, height: 60.h,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: _controller.text.length > 10 ? theme.primaryColor : Colors.grey, boxShadow: [if (_controller.text.length > 10) BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)]),
                    child: Center(child: Text("CRYSTALLIZE MEMORY", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                  ),
                ),
              SizedBox(height: 20.h),
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
          Icon(Icons.auto_awesome_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("MANIFEST YOUR THOUGHTS THROUGH THE FOG", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildJournalPrompt(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(20.r), borderRadius: BorderRadius.circular(24.r),
      color: primaryColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.nightlight_round, color: Colors.amberAccent, size: 24.r).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds),
          SizedBox(width: 16.w),
          Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildScratchArea(String text, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: GestureDetector(
          onPanUpdate: (details) => _onReveal(details.localPosition),
          child: CustomPaint(
            painter: FogPainter(points: _revealPoints, text: text, color: color, isRevealed: _isAnswered),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _buildHiddenInput(Color color) {
    return TextField(
      controller: _controller,
      autofocus: true,
      maxLines: 1,
      style: const TextStyle(color: Colors.transparent),
      decoration: InputDecoration(
        hintText: "Begin typing to manifest...",
        hintStyle: GoogleFonts.outfit(color: color.withValues(alpha: 0.3), fontSize: 14.sp),
        border: InputBorder.none,
      ),
    );
  }
}

class FogPainter extends CustomPainter {
  final List<Offset> points;
  final String text;
  final Color color;
  final bool isRevealed;
  FogPainter({required this.points, required this.text, required this.color, required this.isRevealed});
  @override
  void paint(Canvas canvas, Size size) {
    // Draw Background Parchment
    final bgPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw manifested text
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: GoogleFonts.spectral(fontSize: 18.sp, color: color, height: 1.6)),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width - 40);
    textPainter.paint(canvas, const Offset(20, 20));

    // Draw Fog Overlay
    if (!isRevealed) {
      canvas.saveLayer(Offset.zero & size, Paint());
      final fogPaint = Paint()..shader = LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade900]).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, fogPaint);

      // Eraser/Reveal paths
      final revealPaint = Paint()..color = Colors.black..strokeWidth = 40..strokeCap = StrokeCap.round..blendMode = BlendMode.clear;
      for (var point in points) {
        canvas.drawCircle(point, 25.r, revealPaint);
      }
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
