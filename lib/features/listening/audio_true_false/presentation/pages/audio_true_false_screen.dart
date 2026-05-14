import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AudioTrueFalseScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioTrueFalseScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioTrueFalse,
  });

  @override
  State<AudioTrueFalseScreen> createState() => _AudioTrueFalseScreenState();
}

class _AudioTrueFalseScreenState extends State<AudioTrueFalseScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _tuningValue = 0.5;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(FetchListeningQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onTune(double delta) {
    if (_isAnswered) return;
    setState(() {
      _tuningValue = (_tuningValue + delta / 300).clamp(0.0, 1.0);
      _hapticService.selection();
    });
  }

  void _submitAnswer(bool verdict, String correct) {
    if (_isAnswered) return;
    bool isCorrect = verdict.toString().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _tuningValue = 0.5;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'FACT VERDICTOR!', enableDoubleUp: true);
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ListeningBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 48.h),
              _buildAudioTuner(quest.textToSpeak ?? "", theme.primaryColor),
              SizedBox(height: 40.h),
              _buildSignalScreen(quest.statement ?? "", theme.primaryColor, isDark),
              const Spacer(),
              _buildPolarizedFilters(quest.correctAnswer ?? "", theme.primaryColor),
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
          Icon(Icons.radio_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("TUNE THE SIGNAL TO CATEGORIZE VERDICT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAudioTuner(String tts, Color color) {
    return ScaleButton(
      onTap: () {
        _soundService.playTts(tts);
        _hapticService.selection();
      },
      child: Container(
        width: 80.r, height: 80.r,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1), border: Border.all(color: color, width: 2)),
        child: Icon(Icons.record_voice_over_rounded, color: color, size: 32.r),
      ),
    );
  }

  Widget _buildSignalScreen(String statement, Color color, bool isDark) {
    double clarity = (1.0 - (_tuningValue - 0.5).abs() * 2).clamp(0.0, 1.0);
    return Container(
      width: double.infinity, height: 180.h,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Static
          if (clarity < 0.9)
            ...List.generate(15, (i) => Positioned(
              left: (i * 20).w,
              child: Container(
                width: 2.w, height: 180.h,
                color: Colors.white10.withValues(alpha: 1.0 - clarity),
              ).animate(onPlay: (c) => c.repeat()).moveX(begin: 0, end: 10, duration: 100.ms),
            )),
            
          // The Statement
          Opacity(
            opacity: clarity.clamp(0.1, 1.0),
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Text(statement, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Color.lerp(Colors.white24, Colors.white, clarity))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolarizedFilters(String correct, Color color) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => _onTune(details.delta.dx),
      onHorizontalDragEnd: (_) {
        if (_tuningValue > 0.9) _submitAnswer(true, correct);
        if (_tuningValue < 0.1) _submitAnswer(false, correct);
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFilterZone("FALSE", Colors.redAccent, _tuningValue < 0.2),
              _buildFilterZone("TRUE", Colors.greenAccent, _tuningValue > 0.8),
            ],
          ),
          SizedBox(height: 20.h),
          Slider(
            value: _tuningValue,
            onChanged: (v) => _onTune((v - _tuningValue) * 300),
            activeColor: color,
            inactiveColor: color.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterZone(String label, Color color, bool isActive) {
    return Container(
      width: 120.w, height: 60.h,
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: isActive ? color : color.withValues(alpha: 0.2), width: 2),
      ),
      child: Center(child: Text(label, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: color))),
    );
  }
}

