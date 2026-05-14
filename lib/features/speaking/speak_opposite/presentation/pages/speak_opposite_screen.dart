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

class SpeakOppositeScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeakOppositeScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakOpposite,
  });

  @override
  State<SpeakOppositeScreen> createState() => _SpeakOppositeScreenState();
}

class _SpeakOppositeScreenState extends State<SpeakOppositeScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _pullProgress = 0.0;
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
    if (_pullProgress >= 1.0) {
      _submitAnswer();
    } else {
      setState(() => _pullProgress = 0.0);
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

    if (_isListening && _pullProgress < 1.0) {
      Future.delayed(16.ms, () {
        if (mounted && _isListening) {
          setState(() {
            _pullProgress += 0.02;
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
              _pullProgress = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'POLAR FLIP MASTER!', enableDoubleUp: true);
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
              _buildPositivePole(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              const Spacer(),
              _buildPlasmaPull(theme.primaryColor),
              const Spacer(),
              _buildNegativePole(theme.primaryColor, isDark),
              SizedBox(height: 40.h),
              _buildPolarMic(theme.primaryColor, isDark),
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
          Icon(Icons.unfold_more_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("PULL TO THE NEGATIVE POLE WITH THE OPPOSITE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPositivePole(String text, Color primaryColor, bool isDark) {
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
              style: isTarget ? GoogleFonts.fredoka(color: Colors.redAccent, fontWeight: FontWeight.w900) : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNegativePole(Color primaryColor, bool isDark) {
    return Container(
      width: 200.w, height: 60.h,
      decoration: BoxDecoration(
        color: _pullProgress > 0.9 ? Colors.cyanAccent : Colors.cyanAccent.withValues(alpha: 0.1),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: _pullProgress > 0.9 ? [BoxShadow(color: Colors.cyanAccent, blurRadius: 20)] : [],
      ),
      child: Center(child: Text("NEGATIVE POLE", style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: _pullProgress > 0.9 ? Colors.black : Colors.cyanAccent))),
    );
  }

  Widget _buildPlasmaPull(Color primaryColor) {
    return SizedBox(
      height: 150.h, width: double.infinity,
      child: CustomPaint(
        painter: _PlasmaPainter(progress: _pullProgress),
      ),
    );
  }

  Widget _buildPolarMic(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _onMicDown(),
      onLongPressEnd: (_) => _onMicUp(),
      child: Container(
        width: 90.r, height: 90.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: _isListening ? [Colors.redAccent, Colors.cyanAccent] : [Colors.grey[800]!, Colors.grey[900]!]),
          boxShadow: _isListening ? [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 20)] : [],
        ),
        child: Icon(_isListening ? Icons.swap_vert_rounded : Icons.mic_none_rounded, color: Colors.white, size: 40.r),
      ),
    );
  }
}

class _PlasmaPainter extends CustomPainter {
  final double progress;

  _PlasmaPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.redAccent.withValues(alpha: 0.2)..strokeWidth = 4..style = PaintingStyle.stroke;
    final plasmaPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 6..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height);
    canvas.drawPath(path, paint);

    if (progress > 0) {
      final plasmaPath = Path();
      plasmaPath.moveTo(size.width / 2, 0);
      plasmaPath.lineTo(size.width / 2, size.height * progress);
      canvas.drawPath(plasmaPath, plasmaPaint);
      canvas.drawPath(plasmaPath, Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
