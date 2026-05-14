import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  
  final ValueNotifier<double> _dialRotation = ValueNotifier(0.33); // 0.0 to 1.0 mapping to 0.5x - 2.0x
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
    double oldVal = _dialRotation.value;
    _dialRotation.value = (_dialRotation.value + delta / 300).clamp(0.0, 1.0);
    
    // Haptic tick for every 0.1x change
    if ((oldVal * 10).floor() != (_dialRotation.value * 10).floor()) {
      _hapticService.light();
    }
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
              _dialRotation.value = 0.33; // Default to 1.0x
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
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 30.h),
              ValueListenableBuilder<double>(
                valueListenable: _dialRotation,
                builder: (context, rotation, _) {
                  double speed = 0.5 + (rotation * 1.5);
                  return Column(
                    children: [
                      _buildSpeedGauges(speed, theme.primaryColor),
                      SizedBox(height: 40.h),
                      _buildMechanicalCore(quest.textToSpeak ?? "", speed, theme.primaryColor, rotation),
                    ],
                  );
                }
              ),
              const Spacer(),
              _buildSteamVents(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              SizedBox(height: 20.h),
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
          Text("CALIBRATE SPEED TO DECODE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSpeedGauges(double speed, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed_rounded, color: color, size: 20.r),
            SizedBox(width: 8.w),
            Text("VELOCITY SENSOR", style: GoogleFonts.shareTechMono(fontSize: 12.sp, color: color.withValues(alpha: 0.7))),
          ],
        ),
        SizedBox(height: 4.h),
        Text("${speed.toStringAsFixed(1)}X", style: GoogleFonts.shareTechMono(fontSize: 42.sp, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildMechanicalCore(String tts, double speed, Color color, double rotation) {
    return GestureDetector(
      onPanUpdate: (details) => _onRotate(details.delta.dx + details.delta.dy),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Outer Gear Background
          Transform.rotate(
            angle: rotation * 4,
            child: Icon(Icons.settings_suggest_rounded, size: 220.r, color: color.withValues(alpha: 0.05)),
          ),
          
          // Outer Ring Indicator
          Container(
            width: 180.r, height: 180.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.1), width: 8.r),
            ),
          ),
          
          // Playable Dial
          ScaleButton(
            onTap: () {
              _soundService.playTts(tts, speed: speed);
              _hapticService.selection();
            },
            child: Container(
              width: 130.r, height: 130.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color, color.withValues(alpha: 0.8), color.withValues(alpha: 0.9)],
                  stops: const [0.2, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5),
                  BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 70.r),
                  Positioned(
                    bottom: 25.r,
                    child: Text("LISTEN", style: GoogleFonts.outfit(fontSize: 8.sp, fontWeight: FontWeight.w900, color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
          
          // Tactical Needle
          Transform.rotate(
            angle: (rotation - 0.5) * 3.5,
            child: Container(
              height: 200.h, width: 6.w,
              alignment: Alignment.topCenter,
              child: Container(
                width: 6.w, height: 25.h, 
                decoration: BoxDecoration(
                  color: Colors.orangeAccent, 
                  borderRadius: BorderRadius.circular(3.r),
                  boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.5), blurRadius: 10)],
                ),
              ),
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
        // Logic fix: Only show green/red after submission, and don't reveal correct answer early
        bool isCorrect = _isAnswered && index == correct && _isCorrect == true;
        bool isWrong = _isAnswered && isSelected && _isCorrect == false;

        Color tileColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : (isSelected ? color : Colors.white24));

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: ScaleButton(
            onTap: () => _submitAnswer(index, correct),
            child: GlassTile(
              padding: EdgeInsets.all(16.r), borderRadius: BorderRadius.circular(20.r),
              color: tileColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.verified_rounded : (isWrong ? Icons.error_outline_rounded : Icons.air_rounded),
                    color: tileColor, 
                    size: 20.r
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      options[index], 
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7)
                      )
                    )
                  ),
                  if (isSelected && !_isAnswered) 
                    Icon(Icons.radio_button_checked, color: color, size: 16.r),
                ],
              ),
            ),
          ),
        ).animate(target: isWrong ? 1 : 0).shake(duration: 400.ms);
      }),
    );
  }
}

