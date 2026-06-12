import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/widgets/elevator_pitch_instruction.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/widgets/elevator_pitch_prompt_card.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/widgets/elevator_pitch_chamber_console.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/widgets/elevator_pitch_record_control.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/widgets/elevator_pitch_explanation_card.dart';

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

class _ElevatorPitchScreenState extends State<ElevatorPitchScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  late AnimationController _waveController;
  Timer? _gravityTimer;

  int _lastProcessedIndex = -1;
  bool _isListening = false;
  String _spokenText = "";
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  // Real-time Physics variables
  double _capsuleY =
      0.4; // Position of capsule inside elevator shaft (0.0 to 1.0)
  double _greenZoneY = 0.5; // Center position of green target zone (0.0 to 1.0)

  // Game scores
  int _ticksRecorded = 0;
  int _ticksInAlignment = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _gravityTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.prompt != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _soundService.playTts(quest.prompt!);
      });
    }
  }

  // Propulsion action: fires booster pushing capsule UP
  void _fireBooster() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _capsuleY = (_capsuleY - 0.16).clamp(0.0, 1.0);
    });
  }

  // Dynamic Physical Engine loops running while microphone records
  void _startPhysicalEngine() {
    _ticksRecorded = 0;
    _ticksInAlignment = 0;
    _gravityTimer?.cancel();

    _gravityTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _isAnswered || !_isListening) {
        timer.cancel();
        return;
      }

      setState(() {
        // 1. Gravity acceleration pulls capsule DOWN
        _capsuleY = (_capsuleY + 0.007).clamp(0.0, 1.0);

        // 2. Green target zone floats using a smooth harmonic sine wave
        final double elapsedSec =
            DateTime.now().millisecondsSinceEpoch / 1000.0;
        _greenZoneY = 0.5 + 0.3 * math.sin(elapsedSec * 1.6);

        // 3. Increment calibration alignments
        _ticksRecorded++;
        final double dist = (_capsuleY - _greenZoneY).abs();
        if (dist < 0.14) {
          _ticksInAlignment++;
        }
      });
    });
  }

  void _startListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _spokenText = "Voice capturing initiated...";
      _capsuleY = 0.4;
    });

    _startPhysicalEngine();

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
          // Giving small booster lift upon spoken transcript updates
          _capsuleY = (_capsuleY - 0.04).clamp(0.0, 1.0);
        });
      },
      onDone: () {
        if (mounted) {
          setState(() => _isListening = false);
          _gravityTimer?.cancel();
        }
      },
    );
  }

  void _stopListening(String target) async {
    await _speechService.stop();
    _gravityTimer?.cancel();
    setState(() => _isListening = false);
    _verifySpeech(target);
  }

  void _verifySpeech(String target) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Voice capturing")) {
      _spokenText = "No recording input captured.";
      return;
    }

    // Alignment accuracy score
    final double alignmentAccuracy = _ticksRecorded > 0
        ? (_ticksInAlignment / _ticksRecorded)
        : 0.0;

    // Core requirements:
    // 1. alignmentAccuracy >= 40% (stayed inside the drifting green elevator target bounds)
    // 2. Length of spoken text >= 12 chars
    bool isCorrect = alignmentAccuracy >= 0.40 && _spokenText.length >= 12;

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
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
              _capsuleY = 0.4;
              _greenZoneY = 0.5;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CHIEF BRAND PITCHER!',
            enableDoubleUp: true,
          );
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return RoleplayBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  child: Column(
                    children: [
                      ElevatorPitchInstruction(
                        primaryColor: theme.primaryColor,
                      ),
                      SizedBox(height: 16.h),
                      ElevatorPitchPromptCard(
                        prompt: quest.prompt ?? "",
                        color: theme.primaryColor,
                        isDark: isDark,
                      ),
                      SizedBox(height: 20.h),

                      // Elevator Physical Chamber Layout
                      ElevatorPitchChamberConsole(
                        color: theme.primaryColor,
                        isDark: isDark,
                        capsuleY: _capsuleY,
                        greenZoneY: _greenZoneY,
                        isListening: _isListening,
                        spokenText: _spokenText,
                        waveAnimation: _waveController,
                        onFireBooster: _fireBooster,
                      ),
                      SizedBox(height: 24.h),

                      // Speech input capture controls
                      if (!_isAnswered)
                        ElevatorPitchRecordControl(
                          isListening: _isListening,
                          color: theme.primaryColor,
                          correctAnswer: quest.correctAnswer ?? "",
                          onStartListening: _startListening,
                          onStopListening: _stopListening,
                        ),

                      // Post-answer explanation cards
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: ElevatorPitchExplanationCard(
                          quest: quest,
                          isDark: isDark,
                          isCorrect: _isCorrect,
                          ticksRecorded: _ticksRecorded,
                          ticksInAlignment: _ticksInAlignment,
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
