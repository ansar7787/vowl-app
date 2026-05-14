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
  State<FastSpeechDecoderScreen> createState() =>
      _FastSpeechDecoderScreenState();
}

class _FastSpeechDecoderScreenState extends State<FastSpeechDecoderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<double> _dialRotation = ValueNotifier(
    0.33,
  ); // 0.0 to 1.0 mapping to 0.5x - 2.0x
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _dialRotation.dispose();
    super.dispose();
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
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
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
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
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
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'NUANCE DECODER!',
            enableDoubleUp: true,
          );
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<ListeningBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          useScrolling: true,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 5.h),
                    _buildInstruction(theme.primaryColor),
                    SizedBox(height: 20.h),
                    ValueListenableBuilder<double>(
                      valueListenable: _dialRotation,
                      builder: (context, rotation, _) {
                        // Mapping 0.0-1.0 rotation to 0.3-0.9 TTS speed
                        double speed = 0.3 + (rotation * 0.6);
                        return Column(
                          children: [
                            _buildSpeedGauges(speed * 2, theme.primaryColor), // Visual multiplier for UI
                            SizedBox(height: 20.h),
                            _buildMechanicalCore(
                              quest.textToSpeak ?? "",
                              speed,
                              theme.primaryColor,
                              rotation,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 25.h),
                    _buildSteamVents(
                      quest.options ?? [],
                      quest.correctAnswerIndex ?? 0,
                      theme.primaryColor,
                      isDark,
                    ),
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
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_input_composite_rounded,
            size: 14.r,
            color: primaryColor,
          ),
          SizedBox(width: 12.w),
          Text(
            "CALIBRATE SPEED TO DECODE",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
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
            Icon(Icons.speed_rounded, color: color, size: 16.r),
            SizedBox(width: 8.w),
            Text(
              "VELOCITY SENSOR",
              style: GoogleFonts.shareTechMono(
                fontSize: 10.sp,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          "${speed.toStringAsFixed(1)}X",
          style: GoogleFonts.shareTechMono(
            fontSize: 36.sp,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMechanicalCore(
    String tts,
    double speed,
    Color color,
    double rotation,
  ) {
    return GestureDetector(
      onPanUpdate: (details) => _onRotate(details.delta.dx + details.delta.dy),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Outer Gear Background
          Transform.rotate(
            angle: rotation * 4,
            child: Icon(
              Icons.settings_suggest_rounded,
              size: 180.r,
              color: color.withValues(alpha: 0.05),
            ),
          ),

          // Outer Ring Indicator
          Container(
            width: 150.r,
            height: 150.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.1),
                width: 6.r,
              ),
            ),
          ),

          // Playable Dial
          ScaleButton(
            onTap: () {
              _soundService.playTts(tts, speed: speed);
              _hapticService.selection();
            },
            child: Container(
              width: 110.r,
              height: 110.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.9),
                  ],
                  stops: const [0.2, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 60.r,
                  ),
                  Positioned(
                    bottom: 20.r,
                    child: Text(
                      "LISTEN",
                      style: GoogleFonts.outfit(
                        fontSize: 7.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tactical Needle
          Transform.rotate(
            angle: (rotation - 0.5) * 3.5,
            child: Container(
              height: 170.h,
              width: 4.w,
              alignment: Alignment.topCenter,
              child: Container(
                width: 4.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(2.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteamVents(
    List<String> options,
    int correct,
    Color color,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (index) {
        final isSelected = _selectedIndex == index;
        final isChoiceCorrect =
            _isAnswered && index == correct && _isCorrect == true;
        final isChoiceWrong = _isAnswered && isSelected && _isCorrect == false;

        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: ScaleButton(
            onTap: () => _submitAnswer(index, correct),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isChoiceCorrect
                    ? Colors.greenAccent.withValues(alpha: 0.8)
                    : (isChoiceWrong
                          ? Colors.redAccent.withValues(alpha: 0.8)
                          : (isSelected ? color : const Color(0xFF1E1E24))),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isChoiceCorrect || isChoiceWrong || isSelected 
                      ? Colors.white.withValues(alpha: 0.5) 
                      : color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  // 3D Physical Shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: Offset(0, 4.h),
                    blurRadius: 8,
                  ),
                  if (isSelected || isChoiceCorrect || isChoiceWrong)
                    BoxShadow(
                      color: (isChoiceCorrect ? Colors.greenAccent : (isChoiceWrong ? Colors.redAccent : color)).withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isChoiceCorrect
                        ? Icons.verified_rounded
                        : (isChoiceWrong
                              ? Icons.error_outline_rounded
                              : Icons.air_rounded),
                    color: Colors.white,
                    size: 18.r,
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      options[index],
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isSelected && !_isAnswered)
                    Icon(
                      Icons.radio_button_checked,
                      color: Colors.white,
                      size: 14.r,
                    ),
                ],
              ),
            ),
          ),
        ).animate(target: isChoiceWrong ? 1 : 0).shake(duration: 400.ms);
      }),
    );
  }
}
