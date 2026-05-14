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

class YesNoSpeakingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const YesNoSpeakingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.yesNoSpeaking,
  });

  @override
  State<YesNoSpeakingScreen> createState() => _YesNoSpeakingScreenState();
}

class _YesNoSpeakingScreenState extends State<YesNoSpeakingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _tiltValue = 0.0; // -1.0 (No) to 1.0 (Yes)
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

  void _onTilt(double delta) {
    if (_isAnswered) return;
    setState(() {
      _tiltValue = (_tiltValue + delta).clamp(-1.0, 1.0);
      if (_tiltValue.abs() > 0.8) _hapticService.selection();
    });
  }

  void _onMicDown() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _isListening = true);
  }

  void _onMicUp() {
    if (_isAnswered) return;
    setState(() => _isListening = false);
    if (_tiltValue.abs() > 0.8) {
      _submitAnswer(_tiltValue > 0);
    } else {
      setState(() => _tiltValue = 0.0);
    }
  }

  void _submitAnswer(bool isYes) {
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
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _tiltValue = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'BINARY RESPONDER!', enableDoubleUp: true);
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
              _buildQuestionCard(quest.prompt ?? "BINARY QUESTION?", theme.primaryColor, isDark),
              const Spacer(),
              _buildTiltArena(theme.primaryColor, isDark),
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
          Icon(Icons.edgesensor_high_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("TILT SPHERE TO ZONE AND SPEAK", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r), borderRadius: BorderRadius.circular(24.r),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildTiltArena(Color primaryColor, bool isDark) {
    return SizedBox(
      height: 120.h, width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track
          Container(
            height: 4.h, width: 280.w,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2.r)),
          ),
          // Zones
          Positioned(left: 20.w, child: _buildZone("NO", Colors.redAccent, _tiltValue < -0.8)),
          Positioned(right: 20.w, child: _buildZone("YES", Colors.greenAccent, _tiltValue > 0.8)),
          
          // The Sphere
          GestureDetector(
            onHorizontalDragUpdate: (details) => _onTilt(details.primaryDelta! / 100),
            child: Transform.translate(
              offset: Offset(_tiltValue * 120.w, 0),
              child: Container(
                width: 60.r, height: 60.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.white, primaryColor]),
                  boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 20)],
                ),
                child: Icon(Icons.blur_on_rounded, color: Colors.white70, size: 30.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZone(String label, Color color, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15)] : [],
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isActive ? Colors.white : color)),
    );
  }

  Widget _buildTactileMic(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _onMicDown(),
      onLongPressEnd: (_) => _onMicUp(),
      child: Container(
        width: 100.r, height: 100.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening ? primaryColor : primaryColor.withValues(alpha: 0.1),
          boxShadow: _isListening ? [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)] : [],
        ),
        child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: _isListening ? Colors.white : primaryColor, size: 48.r),
      ),
    );
  }
}
