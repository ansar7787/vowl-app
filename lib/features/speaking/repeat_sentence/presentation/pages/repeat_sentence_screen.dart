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
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RepeatSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const RepeatSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.repeatSentence,
  });

  @override
  State<RepeatSentenceScreen> createState() => _RepeatSentenceScreenState();
}

class _RepeatSentenceScreenState extends State<RepeatSentenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _progress = 0.0;
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
    setState(() {
      _isListening = true;
    });
  }

  void _onMicUp() {
    if (_isAnswered) return;
    setState(() {
      _isListening = false;
    });
    if (_progress >= 1.0) {
      _submitAnswer();
    } else {
      setState(() => _progress = 0.0);
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

    if (_isListening && _progress < 1.0) {
      Future.delayed(16.ms, () {
        if (mounted && _isListening) {
          setState(() {
            _progress += 0.01;
            _hapticService.selection();
          });
        }
      });
    }

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _progress = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'ECHO MASTER!', enableDoubleUp: true);
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
              _buildTargetSentence(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              const Spacer(),
              _buildWaveVisualizer(theme.primaryColor, isDark),
              const Spacer(),
              _buildTactileMic(theme.primaryColor, isDark),
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
          Icon(Icons.graphic_eq_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("HOLD AND TRACE THE SOUND WAVE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTargetSentence(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r), borderRadius: BorderRadius.circular(24.r),
      child: Column(
        children: [
          ScaleButton(
            onTap: () => _soundService.playTts(text),
            child: Icon(Icons.volume_up_rounded, color: primaryColor, size: 32.r),
          ),
          SizedBox(height: 16.h),
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 20.sp, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildWaveVisualizer(Color primaryColor, bool isDark) {
    return SizedBox(
      height: 120.h, width: double.infinity,
      child: CustomPaint(
        painter: _WavePainter(progress: _progress, isListening: _isListening, primaryColor: primaryColor),
      ),
    );
  }

  Widget _buildTactileMic(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _onMicDown(),
      onLongPressEnd: (_) => _onMicUp(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isListening)
            ...List.generate(3, (i) => Container(
              width: 100.r + (i * 30), height: 100.r + (i * 30),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.seconds).fadeOut()),
          
          ScaleButton(
            onTap: () {},
            child: Container(
              width: 90.r, height: 90.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: _isListening ? [primaryColor, primaryColor.withValues(alpha: 0.6)] : [Colors.grey[800]!, Colors.grey[900]!]),
                boxShadow: _isListening ? [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20)] : [],
              ),
              child: Icon(_isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded, color: Colors.white, size: 36.r),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final bool isListening;
  final Color primaryColor;

  _WavePainter({required this.progress, required this.isListening, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final ghostPaint = Paint()..color = primaryColor.withValues(alpha: 0.1)..strokeWidth = 2.r..style = PaintingStyle.stroke;
    final livePaint = Paint()..color = primaryColor..strokeWidth = 4.r..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final corePaint = Paint()..color = Colors.white..strokeWidth = 2.r..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + (sin(x / 20) * 30 * (isListening ? 1.2 : 0.8));
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, ghostPaint);

    if (progress > 0) {
      final tracePath = Path();
      tracePath.moveTo(0, size.height / 2);
      for (double x = 0; x <= size.width * progress; x++) {
        final y = size.height / 2 + (sin(x / 20) * 30 * 1.2);
        tracePath.lineTo(x, y);
      }
      canvas.drawPath(tracePath, livePaint);
      canvas.drawPath(tracePath, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
