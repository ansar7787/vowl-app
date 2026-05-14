import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReadingInferenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingInferenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingInference,
  });

  @override
  State<ReadingInferenceScreen> createState() => _ReadingInferenceScreenState();
}

class _ReadingInferenceScreenState extends State<ReadingInferenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<Offset> _rubPoints = [];
  double _clarity = 0.0;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(FetchReadingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onRub(Offset point) {
    if (_isAnswered) return;
    setState(() {
      _rubPoints.add(point);
      _clarity = (_rubPoints.length / 100).clamp(0.0, 1.0);
      if (_rubPoints.length % 5 == 0) _hapticService.selection();
    });
  }

  void _onChoiceTap(int index, String selected, String correct) {
    if (_isAnswered || _clarity < 0.3) return;
    setState(() => _selectedIndex = index);

    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<ReadingBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _rubPoints.clear();
              _clarity = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'HIDDEN LAYER SYNCED!', enableDoubleUp: true);
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ReadingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ReadingLoaded) ? state.currentQuest : null;
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildFoggyMirror(quest.passage ?? "", theme.primaryColor, isDark),
              SizedBox(height: 32.h),
              Text(quest.question?.toUpperCase() ?? "INFER THE HIDDEN TRUTH", style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 1.5)),
              SizedBox(height: 24.h),
              ...List.generate(quest.options?.length ?? 0, (index) => _buildInferenceOption(index, quest.options![index], quest.correctAnswer ?? "", theme.primaryColor, isDark)),
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
          Icon(Icons.auto_awesome_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("RUB THE MIRROR TO REVEAL CLUES", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildFoggyMirror(String text, Color color, bool isDark) {
    return GestureDetector(
      onPanUpdate: (details) => _onRub(details.localPosition),
      child: Stack(
        children: [
          // Clear Text
          GlassTile(
            padding: EdgeInsets.all(24.r), borderRadius: BorderRadius.circular(24.r),
            color: color.withValues(alpha: 0.1),
            child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          
          // Fog Layer
          if (!_isAnswered)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: CustomPaint(
                  painter: FogPainter(points: _rubPoints, clarity: _clarity, color: isDark ? Colors.white24 : Colors.black26),
                ),
              ),
            ),
          
          // Glowing Clues (Overlays)
          if (_clarity > 0.5)
            Positioned.fill(
              child: Center(
                child: Icon(Icons.lightbulb_outline_rounded, color: Colors.amber.withValues(alpha: 0.3), size: 100.r).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInferenceOption(int index, String text, String correct, Color color, bool isDark) {
    bool isSelected = _selectedIndex == index;
    bool isCorrect = _isAnswered && text.trim().toLowerCase() == correct.trim().toLowerCase();
    bool isWrong = _isAnswered && isSelected && !isCorrect;
    bool isDisabled = _clarity < 0.3 && !_isAnswered;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: () => _onChoiceTap(index, text, correct),
        child: AnimatedOpacity(
          duration: 300.milliseconds,
          opacity: isDisabled ? 0.4 : 1.0,
          child: GlassTile(
            padding: EdgeInsets.all(20.r), borderRadius: BorderRadius.circular(20.r),
            color: isCorrect ? Colors.greenAccent.withValues(alpha: 0.3) : (isWrong ? Colors.redAccent.withValues(alpha: 0.3) : (isSelected ? color.withValues(alpha: 0.2) : Colors.white10)),
            child: Center(child: Text(text, style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
        ),
      ),
    );
  }
}

class FogPainter extends CustomPainter {
  final List<Offset> points;
  final double clarity;
  final Color color;
  FogPainter({required this.points, required this.clarity, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.9 - (clarity * 0.5))..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    final clearPaint = Paint()..blendMode = BlendMode.clear..strokeWidth = 40..strokeCap = StrokeCap.round..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], clearPaint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

