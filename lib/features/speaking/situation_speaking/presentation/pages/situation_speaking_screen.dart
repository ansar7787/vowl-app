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

class SituationSpeakingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SituationSpeakingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.situationSpeaking,
  });

  @override
  State<SituationSpeakingScreen> createState() => _SituationSpeakingScreenState();
}

class _SituationSpeakingScreenState extends State<SituationSpeakingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _scrubProgress = 0.0;
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

  void _onScrub(double delta) {
    if (_isAnswered || _scrubProgress >= 1.0) return;
    setState(() {
      _scrubProgress = (_scrubProgress + delta).clamp(0.0, 1.0);
      if (_scrubProgress > 0) _hapticService.selection();
      if (_scrubProgress >= 1.0) _hapticService.success();
    });
  }

  void _onMicTap() {
    if (_isAnswered || _scrubProgress < 1.0) return;
    _hapticService.selection();
    setState(() => _isListening = !_isListening);
    if (!_isListening) {
      _submitAnswer();
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
              _scrubProgress = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SOCIAL BUTTERFLY!', enableDoubleUp: true);
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
              _buildScrubbableScene(quest.situationText ?? "SITUATION", theme.primaryColor, isDark),
              const Spacer(),
              _buildMicButton(theme.primaryColor, isDark),
              SizedBox(height: 48.h),
              Text(
                _scrubProgress < 1.0 ? "WIPE TO REVEAL" : (_isListening ? "RECORDING RESPONSE..." : "TAP TO RESPOND"), 
                style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: _scrubProgress < 1.0 ? Colors.grey : theme.primaryColor, letterSpacing: 2)
              ),
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
          Icon(Icons.cleaning_services_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("WIPE THE GLASS TO SEE THE SCENE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildScrubbableScene(String text, Color primaryColor, bool isDark) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => _onScrub(details.primaryDelta! / 300),
      child: Stack(
        children: [
          // The Content
          GlassTile(
            padding: EdgeInsets.all(32.r), borderRadius: BorderRadius.circular(24.r),
            color: primaryColor.withValues(alpha: 0.1),
            child: Opacity(
              opacity: _scrubProgress,
              child: Column(
                children: [
                  Icon(Icons.theater_comedy_rounded, color: primaryColor, size: 48.r),
                  SizedBox(height: 24.h),
                  Text(text, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            ),
          ),
          // The Fog
          if (_scrubProgress < 1.0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.grey[900] : Colors.white)!.withValues(alpha: 1.0 - _scrubProgress),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Center(
                    child: Icon(Icons.blur_on_rounded, color: primaryColor.withValues(alpha: 0.5), size: 64.r),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMicButton(Color primaryColor, bool isDark) {
    final isEnabled = _scrubProgress >= 1.0;
    return ScaleButton(
      onTap: isEnabled ? _onMicTap : null,
      child: Container(
        width: 100.r, height: 100.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled ? (_isListening ? primaryColor : primaryColor.withValues(alpha: 0.1)) : Colors.grey.withValues(alpha: 0.1),
          boxShadow: _isListening ? [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)] : [],
        ),
        child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: isEnabled ? (_isListening ? Colors.white : primaryColor) : Colors.grey, size: 48.r),
      ),
    );
  }
}
