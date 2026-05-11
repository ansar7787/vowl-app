import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DailyExpressionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DailyExpressionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dailyExpression,
  });

  @override
  State<DailyExpressionScreen> createState() => _DailyExpressionScreenState();
}

class _DailyExpressionScreenState extends State<DailyExpressionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _scratchProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onMicDown() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _isListening = true);
  }

  void _onMicUp() {
    if (_isAnswered) return;
    setState(() => _isListening = false);
    if (_scratchProgress >= 1.0) {
      _submitAnswer();
    } else {
      setState(() => _scratchProgress = 0.0);
    }
  }

  void _submitAnswer() {
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<SpeakingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);

    if (_isListening && _scratchProgress < 1.0) {
      Future.delayed(16.ms, () {
        if (mounted && _isListening) {
          setState(() {
            _scratchProgress += 0.015;
            _hapticService.selection();
          });
        }
      });
    }

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _scratchProgress = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'IDIOM VERBALIZER!', enableDoubleUp: true);
        } else if (state is SpeakingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<SpeakingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        
        return SpeakingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
          onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 48.h),
              _buildScratchCard(quest.expression ?? "IDIOM", quest.meaning ?? "MEANING", theme.primaryColor, isDark),
              const Spacer(),
              _buildUsagePlate(quest.sampleUsage ?? "EXAMPLE", theme.primaryColor, isDark),
              const Spacer(),
              _buildTactileScratcher(theme.primaryColor, isDark),
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
          Icon(Icons.auto_fix_high_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SCRATCH OFF THE IDIOM TO REVEAL", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildScratchCard(String expression, String meaning, Color primaryColor, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Content (Behind)
          GlassTile(
            padding: EdgeInsets.all(32.r), borderRadius: BorderRadius.circular(24.r),
            color: primaryColor.withValues(alpha: 0.1),
            child: Column(
              children: [
                Text(expression, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 26.sp, fontWeight: FontWeight.w900, color: primaryColor)),
                SizedBox(height: 12.h),
                Text(meaning.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white54 : Colors.black45, letterSpacing: 1)),
              ],
            ),
          ),
          
          // The Scratch Coating
          if (_scratchProgress < 0.95)
            ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                width: 320.w, height: 160.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[400]!, Colors.grey[600]!, Colors.grey[400]!],
                    stops: [0, 0.5, 1],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: CustomPaint(
                  painter: _ScratchPainter(progress: _scratchProgress),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsagePlate(String usage, Color primaryColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.r),
      child: Text("\"$usage\"", textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black54, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildTactileScratcher(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _onMicDown(),
      onLongPressEnd: (_) => _onMicUp(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isListening)
            ...List.generate(8, (i) => Icon(Icons.star_rounded, color: Colors.amberAccent, size: 16.r)
              .animate(onPlay: (c) => c.repeat())
              .moveX(begin: 0, end: (i % 2 == 0 ? 50 : -50), duration: 400.ms)
              .moveY(begin: 0, end: -40, duration: 400.ms)
              .fadeOut()),
              
          Container(
            width: 90.r, height: 90.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? primaryColor : primaryColor.withValues(alpha: 0.1),
              boxShadow: _isListening ? [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20)] : [],
            ),
            child: Icon(_isListening ? Icons.auto_fix_normal_rounded : Icons.mic_none_rounded, color: Colors.white, size: 36.r),
          ),
        ],
      ),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final double progress;

  _ScratchPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.clear;
    
    // Simple vertical reveal for scratch-off
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * progress, size.height), paint);
    
    // Add "scratch lines" at the edge
    final edgePaint = Paint()..color = Colors.white24..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * progress, 0), Offset(size.width * progress, size.height), edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
