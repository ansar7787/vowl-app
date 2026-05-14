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
import 'package:flutter_animate/flutter_animate.dart';

class SpeakSynonymScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeakSynonymScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakSynonym,
  });

  @override
  State<SpeakSynonymScreen> createState() => _SpeakSynonymScreenState();
}

class _SpeakSynonymScreenState extends State<SpeakSynonymScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _bloomProgress = 0.0;
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
    if (_bloomProgress >= 1.0) {
      _submitAnswer();
    } else {
      setState(() => _bloomProgress = 0.0);
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

    if (_isListening && _bloomProgress < 1.0) {
      Future.delayed(16.ms, () {
        if (mounted && _isListening) {
          setState(() {
            _bloomProgress += 0.015;
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
              _bloomProgress = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'LEXICAL PIVOT!', enableDoubleUp: true);
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
              _buildSynonymSeed(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              const Spacer(),
              _buildBloomingGarden(theme.primaryColor, isDark),
              const Spacer(),
              _buildTactileWateringMic(theme.primaryColor, isDark),
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
          Icon(Icons.eco_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SPEAK SYNONYM TO BLOOM THE FLOWER", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSynonymSeed(String text, Color primaryColor, bool isDark) {
    List<String> parts = text.split('*');
    return GlassTile(
      padding: EdgeInsets.all(24.r), borderRadius: BorderRadius.circular(24.r),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.fredoka(fontSize: 20.sp, color: isDark ? Colors.white70 : Colors.black54),
          children: parts.asMap().entries.map((e) {
            bool isTarget = e.key % 2 != 0;
            return TextSpan(
              text: e.value,
              style: isTarget ? GoogleFonts.fredoka(color: primaryColor, fontWeight: FontWeight.w900, decoration: TextDecoration.underline) : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBloomingGarden(Color primaryColor, bool isDark) {
    return SizedBox(
      height: 200.h, width: double.infinity,
      child: CustomPaint(
        painter: _BloomPainter(progress: _bloomProgress, primaryColor: primaryColor),
      ),
    );
  }

  Widget _buildTactileWateringMic(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _onMicDown(),
      onLongPressEnd: (_) => _onMicUp(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isListening)
            ...List.generate(5, (i) => Icon(Icons.water_drop_rounded, color: Colors.cyanAccent, size: 24.r)
              .animate(onPlay: (c) => c.repeat())
              .moveY(begin: 0, end: -100, duration: (500 + i * 100).ms, curve: Curves.easeOut)
              .fadeOut()),
          
          Container(
            width: 90.r, height: 90.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: _isListening ? [primaryColor, primaryColor.withValues(alpha: 0.6)] : [Colors.grey[800]!, Colors.grey[900]!]),
              boxShadow: _isListening ? [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20)] : [],
            ),
            child: Icon(_isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded, color: Colors.white, size: 36.r),
          ),
        ],
      ),
    );
  }
}

class _BloomPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _BloomPainter({required this.progress, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = primaryColor..style = PaintingStyle.fill;
    final glowPaint = Paint()..color = primaryColor.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Draw Petals
    final numPetals = 8;
    for (int i = 0; i < numPetals; i++) {
      final angle = (i * 3.14 * 2) / numPetals;
      final petalDist = 60.r * progress;
      final petalSize = 30.r * progress;
      
      canvas.drawCircle(Offset(center.dx + cos(angle) * petalDist, center.dy + sin(angle) * petalDist), petalSize, paint);
      canvas.drawCircle(Offset(center.dx + cos(angle) * petalDist, center.dy + sin(angle) * petalDist), petalSize + 5, glowPaint);
    }
    
    // Core
    canvas.drawCircle(center, 20.r + (10.r * progress), Paint()..color = Colors.white);
    canvas.drawCircle(center, 25.r + (15.r * progress), glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
