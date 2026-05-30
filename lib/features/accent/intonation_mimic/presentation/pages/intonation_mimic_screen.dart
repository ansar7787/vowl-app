import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_instruction.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_prompt_card.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_rollercoaster.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_pulse_speaker.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_spectral_slider.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_explanation_card.dart';

class IntonationMimicScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const IntonationMimicScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.intonationMimic,
  });

  @override
  State<IntonationMimicScreen> createState() => _IntonationMimicScreenState();
}

class _IntonationMimicScreenState extends State<IntonationMimicScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _sliderValue = 0.5;
  int? _selectedIndex;

  // Pitch ride animation parameters
  double _cartPosition = 0.0;
  bool _isRiding = false;
  Timer? _rideTimer;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _rideTimer?.cancel();
    super.dispose();
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
    _triggerRideEffect();
  }

  void _triggerRideEffect() {
    _rideTimer?.cancel();
    setState(() {
      _cartPosition = 0.0;
      _isRiding = true;
    });

    const steps = 30;
    const interval = Duration(milliseconds: 40);
    int currentStep = 0;

    _rideTimer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      setState(() {
        _cartPosition = (currentStep / steps).clamp(0.0, 1.0);
      });
      if (currentStep >= steps) {
        timer.cancel();
        setState(() => _isRiding = false);
      }
    });
  }

  void _onSliderUpdate(double value, int correct) {
    if (_isAnswered) return;
    setState(() => _sliderValue = value);
    
    // Auto-lock when reaching ends
    if (value < 0.1) {
      _submitChoice(0, correct);
    } else if (value > 0.9) {
      _submitChoice(1, correct);
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered) return;
    setState(() {
      _selectedIndex = index;
      _sliderValue = index == 0 ? 0.0 : 1.0;
    });
    
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<AccentBloc>().add(SubmitAnswer(false));
      
      Future.delayed(2.seconds, () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _selectedIndex = null;
            _sliderValue = 0.5;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _sliderValue = 0.5;
              _selectedIndex = null;
              _cartPosition = 0.0;
              _isRiding = false;
            });
            // Proactively auto-play sound and trigger ride effect on load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                  _triggerRideEffect();
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CONTOUR MASTER!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded) ? state.currentQuest as AccentQuest? : null;
        final options = quest?.options ?? ["A", "B"];
        final contour = quest?.intonationMap ?? [1, 2, 1, 0];

        return AccentBaseLayout(
          gameType: widget.gameType, 
          level: widget.level, 
          isAnswered: _isAnswered, 
          isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  IntonationMimicInstruction(color: theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  IntonationMimicPromptCard(
                    word: quest.word ?? "",
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  
                  IntonationMimicRollercoaster(
                    contour: contour,
                    color: theme.primaryColor,
                    isDark: isDark,
                    isRiding: _isRiding,
                    cartPosition: _cartPosition,
                  ),
                  SizedBox(height: 32.h),
                  
                  IntonationMimicPulseSpeaker(
                    text: quest.textToSpeak ?? "",
                    color: theme.primaryColor,
                    onPlayTts: _playTts,
                  ),
                  SizedBox(height: 48.h),
                  
                  IntonationMimicSpectralSlider(
                    options: options,
                    correctIndex: quest.correctAnswerIndex ?? 0,
                    color: theme.primaryColor,
                    isDark: isDark,
                    isAnswered: _isAnswered,
                    selectedIndex: _selectedIndex,
                    sliderValue: _sliderValue,
                    onSubmitChoice: _submitChoice,
                    onSliderUpdate: _onSliderUpdate,
                  ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 40.h),
                    IntonationMimicExplanationCard(
                      quest: quest,
                      color: theme.primaryColor,
                      isDark: isDark,
                      isCorrect: _isCorrect,
                    ),
                  ],
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
