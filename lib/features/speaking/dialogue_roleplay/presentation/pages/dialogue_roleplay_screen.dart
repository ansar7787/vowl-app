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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DialogueRoleplayScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DialogueRoleplayScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dialogueRoleplay,
  });

  @override
  State<DialogueRoleplayScreen> createState() => _DialogueRoleplayScreenState();
}

class _DialogueRoleplayScreenState extends State<DialogueRoleplayScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _powerLevel = 0.0;
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
    if (_powerLevel >= 1.0) {
      _submitAnswer();
    } else {
      setState(() => _powerLevel = 0.0);
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

    if (_isListening && _powerLevel < 1.0) {
      Future.delayed(16.ms, () {
        if (mounted && _isListening) {
          setState(() {
            _powerLevel += 0.02;
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
              _powerLevel = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'EXCHANGE MASTER!', enableDoubleUp: true);
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
              SizedBox(height: 24.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildCircuitTerminal(quest.partnerDialogue ?? "TERMINAL INPUT...", quest.sampleAnswer ?? "EXPECTED OUTPUT...", theme.primaryColor, isDark),
              const Spacer(),
              _buildPowerCore(theme.primaryColor, isDark),
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
          Icon(Icons.bolt_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("POWER UP THE RESPONSE CIRCUIT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCircuitTerminal(String partner, String response, Color primaryColor, bool isDark) {
    return Column(
      children: [
        _buildNodeBubble(partner, false, primaryColor, isDark),
        SizedBox(height: 32.h),
        CustomPaint(
          size: Size(double.infinity, 40.h),
          painter: _CircuitLinkPainter(progress: _powerLevel, color: primaryColor),
        ),
        SizedBox(height: 8.h),
        _buildNodeBubble(response, true, primaryColor, isDark),
      ],
    );
  }

  Widget _buildNodeBubble(String text, bool isOutput, Color primaryColor, bool isDark) {
    final opacity = isOutput ? 0.3 + (0.7 * _powerLevel) : 1.0;
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isOutput ? 0.05 : 0.15),
        border: Border.all(color: isOutput ? primaryColor.withValues(alpha: _powerLevel) : primaryColor.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isOutput && _powerLevel > 0.8 ? [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20)] : [],
      ),
      child: Opacity(
        opacity: opacity,
        child: Text(
          text, textAlign: TextAlign.center,
          style: GoogleFonts.shareTechMono(fontSize: 16.sp, color: isOutput ? primaryColor : (isDark ? Colors.white70 : Colors.black87))
        ),
      ),
    );
  }

  Widget _buildPowerCore(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _onMicDown(),
      onLongPressEnd: (_) => _onMicUp(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100.r, height: 100.r,
            child: CircularProgressIndicator(
              value: _powerLevel,
              strokeWidth: 4.r,
              color: primaryColor,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
            ),
          ),
          ScaleButton(
            onTap: () {},
            child: Container(
              width: 80.r, height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? primaryColor : Colors.grey[900],
                boxShadow: _isListening ? [BoxShadow(color: primaryColor.withValues(alpha: 0.5), blurRadius: 20)] : [],
              ),
              child: Icon(_isListening ? Icons.electric_bolt_rounded : Icons.mic_none_rounded, color: Colors.white, size: 36.r),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircuitLinkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircuitLinkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.2)..strokeWidth = 2..style = PaintingStyle.stroke;
    final activePaint = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height);
    
    canvas.drawPath(path, paint);

    if (progress > 0) {
      final activePath = Path();
      activePath.moveTo(size.width / 2, 0);
      activePath.lineTo(size.width / 2, size.height * progress);
      canvas.drawPath(activePath, activePaint);
      canvas.drawPath(activePath, Paint()..color = Colors.white..strokeWidth = 1..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
