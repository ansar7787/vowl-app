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

class PronunciationFocusScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PronunciationFocusScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pronunciationFocus,
  });

  @override
  State<PronunciationFocusScreen> createState() => _PronunciationFocusScreenState();
}

class _PronunciationFocusScreenState extends State<PronunciationFocusScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _heatLevel = 0.0;
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
    if (_heatLevel >= 1.0) {
      _submitAnswer();
    } else {
      setState(() => _heatLevel = 0.0);
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

    if (_isListening && _heatLevel < 1.0) {
      Future.delayed(16.ms, () {
        if (mounted && _isListening) {
          setState(() {
            _heatLevel += 0.012;
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
              _heatLevel = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CRYSTAL CLARITY!', enableDoubleUp: true);
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
              SizedBox(height: 40.h),
              _buildThermalTarget(quest.targetPhoneme ?? "PHONEME", theme.primaryColor),
              SizedBox(height: 24.h),
              _buildHeatmapSentence(quest.textToSpeak ?? "PRONOUNCE THIS.", theme.primaryColor, isDark),
              const Spacer(),
              _buildSizzleMic(theme.primaryColor, isDark),
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
          Icon(Icons.whatshot_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("HEAT THE PLATE TO CRITICAL MASS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildThermalTarget(String phoneme, Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.blue[900], Colors.orange[900], _heatLevel),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white24),
        boxShadow: [BoxShadow(color: Color.lerp(Colors.blue, Colors.orange, _heatLevel)!.withValues(alpha: 0.5), blurRadius: 15)],
      ),
      child: Text(phoneme, style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }

  Widget _buildHeatmapSentence(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(32.r), borderRadius: BorderRadius.circular(24.r),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 22.sp, color: Color.lerp(isDark ? Colors.white54 : Colors.black54, Colors.orangeAccent, _heatLevel))),
          if (_isListening)
            ...List.generate(3, (i) => Container(
              width: 200.w, height: 60.h,
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30.r),
              ),
            ).animate(onPlay: (c) => c.repeat()).moveX(begin: -5, end: 5, duration: 200.ms).moveY(begin: -2, end: 2, duration: 300.ms)),
        ],
      ),
    );
  }

  Widget _buildSizzleMic(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _onMicDown(),
      onLongPressEnd: (_) => _onMicUp(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100.r, height: 100.r,
            child: CircularProgressIndicator(
              value: _heatLevel,
              strokeWidth: 6.r,
              color: Colors.orangeAccent,
              backgroundColor: Colors.blue[900]!.withValues(alpha: 0.3),
            ),
          ),
          ScaleButton(
            onTap: () {},
            child: Container(
              width: 80.r, height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.orange[800] : Colors.blue[900],
                boxShadow: _isListening ? [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.5), blurRadius: 25)] : [],
              ),
              child: Icon(_isListening ? Icons.local_fire_department_rounded : Icons.mic_none_rounded, color: Colors.white, size: 36.r),
            ),
          ),
        ],
      ),
    );
  }
}
