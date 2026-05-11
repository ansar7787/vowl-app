import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ElevatorPitchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ElevatorPitchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.elevatorPitch,
  });

  @override
  State<ElevatorPitchScreen> createState() => _ElevatorPitchScreenState();
}

class _ElevatorPitchScreenState extends State<ElevatorPitchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();
  
  int _lastProcessedIndex = -1;
  bool _isListening = false;
  String _spokenText = "";
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _capsuleY = 0.5; // Normalized 0.0 to 1.0

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onPitchTap() {
    if (_isAnswered) return;
    setState(() {
      _capsuleY = (_capsuleY - 0.1).clamp(0.0, 1.0);
    });
    _hapticService.selection();
  }

  void _startListening() async {
    if (_isAnswered) return;
    _hapticService.selection();
    
    setState(() {
      _isListening = true;
      _spokenText = "Pitching...";
    });

    _speechService.listen(
      onResult: (text) => setState(() => _spokenText = text),
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  void _stopListening(String target) async {
    await _speechService.stop();
    setState(() => _isListening = false);
    _verifySpeech(target);
  }

  void _verifySpeech(String target) {
    if (_spokenText.isEmpty || _spokenText == "Pitching...") return;
    
    // Logic for elevator pitch success
    bool isCorrect = _spokenText.length > 5; // Simplified for now

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
      });
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _spokenText = "";
              _isListening = false;
              _capsuleY = 0.5;
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SILVER TONGUE!', enableDoubleUp: true);
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return RoleplayBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildElevatorShaft(theme.primaryColor),
              _buildPitchCapsule(theme.primaryColor),
              _buildPitchDisplay(quest.prompt ?? "", theme.primaryColor, isDark),
              if (!_isAnswered) _buildMicButton(theme.primaryColor, quest.correctAnswer ?? ""),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Positioned(
      top: 10.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Text("KEEP THE PITCH CAPSULE IN THE GREEN ZONE WHILE SPEAKING", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildElevatorShaft(Color color) {
    return Positioned(
      left: 30.w,
      top: 100.h,
      bottom: 200.h,
      child: Container(
        width: 40.w,
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Green Zone
            AnimatedPositioned(
              duration: 2.seconds,
              curve: Curves.easeInOut,
              top: 100.h, // Dynamic movement logic would go here
              child: Container(
                width: 40.w, height: 80.h,
                decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20.r)),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(color: Colors.greenAccent.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPitchCapsule(Color color) {
    return Positioned(
      left: 30.w,
      top: 100.h + (300.h * _capsuleY),
      child: GestureDetector(
        onTap: _onPitchTap,
        child: Container(
          width: 40.w, height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)],
          ),
          child: Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20.r),
        ),
      ),
    );
  }

  Widget _buildPitchDisplay(String prompt, Color color, bool isDark) {
    return Positioned(
      top: 100.h,
      right: 20.w,
      left: 90.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.1))),
            child: Column(
              children: [
                Text(prompt, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                SizedBox(height: 12.h),
                Text(_spokenText, style: GoogleFonts.outfit(fontSize: 14.sp, color: color, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(Color color, String target) {
    return Positioned(
      bottom: 60.h,
      child: GestureDetector(
        onLongPressStart: (_) => _startListening(),
        onLongPressEnd: (_) => _stopListening(target),
        child: ScaleButton(
          onTap: () {},
          child: Container(
            width: 100.r, height: 100.r,
            decoration: BoxDecoration(
              color: _isListening ? Colors.redAccent : color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: (_isListening ? Colors.redAccent : color).withValues(alpha: 0.3), blurRadius: 20)],
            ),
            child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: Colors.white, size: 48.r),
          ),
        ),
      ),
    );
  }
}

