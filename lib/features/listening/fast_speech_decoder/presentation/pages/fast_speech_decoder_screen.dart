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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class FastSpeechDecoderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FastSpeechDecoderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.fastSpeechDecoder,
  });

  @override
  State<FastSpeechDecoderScreen> createState() => _FastSpeechDecoderScreenState();
}

class _FastSpeechDecoderScreenState extends State<FastSpeechDecoderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _dialRotation = 0.0; // 0.0 to 1.0 (0.5x to 2.0x)
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(FetchListeningQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onRotate(double delta) {
    if (_isAnswered) return;
    setState(() {
      _dialRotation = (_dialRotation + delta / 500).clamp(0.0, 1.0);
      _hapticService.selection();
    });
  }

  void _submitAnswer(int index, int correct) {
    if (_isAnswered) return;
    setState(() => _selectedIndex = index);
    bool isCorrect = index == correct;

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
              _selectedIndex = null;
              _dialRotation = 0.5;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'NUANCE DECODER!', enableDoubleUp: true);
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ListeningBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;
        double speed = 0.5 + (_dialRotation * 1.5);
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 40.h),
              _buildSpeedGauges(speed, theme.primaryColor),
              const Spacer(),
              _buildMechanicalCore(quest.textToSpeak ?? "", speed, theme.primaryColor),
              const Spacer(),
              _buildSteamVents(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
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
          Icon(Icons.settings_input_composite_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("CALIBRATE SPEED TO DECODE SPEECH", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSpeedGauges(double speed, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.speed_rounded, color: color, size: 24.r),
        SizedBox(width: 12.w),
        Text("${speed.toStringAsFixed(1)}X", style: GoogleFonts.shareTechMono(fontSize: 32.sp, fontWeight: FontWeight.w900, color: color)),
        SizedBox(width: 12.w),
        Text("PLAYBACK VELOCITY", style: GoogleFonts.shareTechMono(fontSize: 12.sp, color: color.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildMechanicalCore(String tts, double speed, Color color) {
    return GestureDetector(
      onPanUpdate: (details) => _onRotate(details.delta.dx + details.delta.dy),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Outer Gear
          Transform.rotate(
            angle: _dialRotation * 6.28,
            child: Icon(Icons.settings_suggest_rounded, size: 180.r, color: color.withValues(alpha: 0.1)),
          ),
          
          // The Playable Dial
          ScaleButton(
            onTap: () {
              _soundService.playTts(tts, speed: speed);
              _hapticService.selection();
            },
            child: Container(
              width: 120.r, height: 120.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.7)]),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)],
              ),
              child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 60.r),
            ),
          ),
          
          // Speed Indicator Notch
          Transform.rotate(
            angle: (_dialRotation - 0.5) * 4.0,
            child: Container(
              height: 140.h, width: 4.w,
              alignment: Alignment.topCenter,
              child: Container(width: 4.w, height: 15.h, decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(2.r))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteamVents(List<String> options, int correct, Color color, bool isDark) {
    return Column(
      children: List.generate(options.length, (index) {
        bool isSelected = _selectedIndex == index;
        bool isCorrect = _isAnswered && index == correct && _isCorrect == true;
        bool isWrong = _isAnswered && isSelected && _isCorrect == false;
        Color tileColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : (isSelected ? Colors.orangeAccent : Colors.white24));

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: ScaleButton(
            onTap: () => _submitAnswer(index, correct),
            child: GlassTile(
              padding: EdgeInsets.all(16.r), borderRadius: BorderRadius.circular(15.r),
              color: tileColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.air_rounded, color: tileColor),
                  SizedBox(width: 16.w),
                  Expanded(child: Text(options[index], style: GoogleFonts.outfit(fontSize: 14.sp, color: isSelected ? Colors.white : Colors.white70))),
                  if (isCorrect) Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                  if (isWrong) Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

