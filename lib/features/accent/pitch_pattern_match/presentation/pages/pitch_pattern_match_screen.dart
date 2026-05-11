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
import 'package:vowl/core/presentation/widgets/scale_button.dart';


class PitchPatternMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PitchPatternMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pitchPatternMatch,
  });

  @override
  State<PitchPatternMatchScreen> createState() => _PitchPatternMatchScreenState();
}

class _PitchPatternMatchScreenState extends State<PitchPatternMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isDrawing = false;
  final List<Offset> _points = [];

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onDrawTap() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
       _isDrawing = !_isDrawing;
       if (_isDrawing) {
          _points.clear();
       }
    });
    
    if (!_isDrawing) {
      _submitAnswer();
    }
  }

  void _submitAnswer() {
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<AccentBloc>().add(SubmitAnswer(true));
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
              _isDrawing = false;
              _points.clear();
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'MELODY SYNCER!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is AccentLoaded) ? state.currentQuest : null;
        final pattern = quest?.pitchPatterns ?? [0, 1, 2, 1, 0];

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildSentenceHeader(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              _buildMelodicCanvas(pattern, theme.primaryColor, isDark),
              _buildCanvasControls(theme.primaryColor, isDark),
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
        child: Text("TRACE THE MELODIC BLUEPRINT WITH YOUR VOICE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSentenceHeader(String text, Color color, bool isDark) {
    return Positioned(
      top: 80.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: () => _soundService.playTts(text),
            child: Icon(Icons.music_note_rounded, color: color, size: 40.r),
          ),
          SizedBox(height: 12.h),
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMelodicCanvas(List<int> pattern, Color color, bool isDark) {
    return Positioned(
      top: 220.h,
      child: Container(
        width: 0.9.sw, height: 200.h,
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.white12,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            // Blueprint
            CustomPaint(
              size: Size(0.9.sw, 200.h),
              painter: _BlueprintPainter(pattern, color.withValues(alpha: 0.15)),
            ),
            // User Ink
            if (_isDrawing || _isAnswered)
              CustomPaint(
                size: Size(0.9.sw, 200.h),
                painter: _InkPainter(_points, color),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasControls(Color color, bool isDark) {
    return Positioned(
      bottom: 60.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: _onDrawTap,
            child: Container(
              width: 100.r, height: 100.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isDrawing ? color : color.withValues(alpha: 0.1),
                border: Border.all(color: color, width: 3),
                boxShadow: _isDrawing ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)] : [],
              ),
              child: Icon(_isDrawing ? Icons.stop_rounded : Icons.create_rounded, color: _isDrawing ? Colors.white : color, size: 48.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(_isDrawing ? "DRAWING MELODY..." : "TAP TO START DRAWING", style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color, letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  final List<int> pattern;
  final Color color;
  _BlueprintPainter(this.pattern, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    double dx = size.width / (pattern.length - 1);
    path.moveTo(0, size.height - (pattern[0] / 2.0 * size.height));

    for (int i = 1; i < pattern.length; i++) {
      path.lineTo(i * dx, size.height - (pattern[i] / 2.0 * size.height));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InkPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  _InkPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (var p in points) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
