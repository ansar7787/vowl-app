import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_instruction.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_prompt_card.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_waveform_trace.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_pulse_speaker.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_spectral_slider.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_explanation_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShadowingChallengeScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ShadowingChallengeScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.shadowingChallenge,
  });

  @override
  State<ShadowingChallengeScreen> createState() => _ShadowingChallengeScreenState();
}

class _ShadowingChallengeScreenState extends State<ShadowingChallengeScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _sliderValue = 0.5;
  int? _selectedIndex;

  double _traceProgress = 0.0;
  bool _isPreviewing = false;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
    _triggerPreviewWave();
  }

  void _triggerPreviewWave() {
    _previewTimer?.cancel();
    setState(() {
      _traceProgress = 0.0;
      _isPreviewing = true;
    });

    const steps = 30;
    const interval = Duration(milliseconds: 40);
    int currentStep = 0;

    _previewTimer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      setState(() {
        _traceProgress = (currentStep / steps).clamp(0.0, 1.0);
      });
      if (currentStep >= steps) {
        timer.cancel();
        setState(() => _isPreviewing = false);
      }
    });
  }

  void _onSliderUpdate(double value, int correct) {
    if (_isAnswered) return;
    setState(() => _sliderValue = value);
    _hapticService.selection();

    // Auto-lock when reaching extremes
    if (value < 0.1) {
      _submitChoice(0, correct);
    } else if (value > 0.9) {
      _submitChoice(1, correct);
    }
  }

  void _onSliderRelease() {
    if (_isAnswered) return;
    setState(() {
      _sliderValue = 0.5;
    });
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
              _traceProgress = 0.0;
              _isPreviewing = false;
            });
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                  _triggerPreviewWave();
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SHADOW GHOST!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded) ? state.currentQuest as AccentQuest? : null;
        final options = quest?.options ?? ["A", "B"];
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: AccentBaseLayout(
            gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
            showConfetti: _showConfetti,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            child: quest == null ? const SizedBox() : LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = constraints.maxHeight;
                final bool isCompact = maxHeight < 580;
                
                final double estimatedContentHeight = 24.h + (isCompact ? 90.h : 120.h) + (isCompact ? 80.h : 110.h) + (isCompact ? 130.h : 172.h) + (_isAnswered ? (isCompact ? 110.h : 160.h) : 0);
                final remainingHeight = maxHeight - estimatedContentHeight;
                
                final double gapUnit = remainingHeight > 0 ? remainingHeight / 8 : 0;
                final double gapTop = remainingHeight > 0 ? (gapUnit * 1).clamp(8.0, 24.0) : 8.0;
                final double gapInstruction = remainingHeight > 0 ? (gapUnit * 1).clamp(8.0, 24.0) : 8.0;
                final double gapPrompt = remainingHeight > 0 ? (gapUnit * 1.5).clamp(12.0, 32.0) : 12.0;
                final double gapSpeaker = remainingHeight > 0 ? (gapUnit * 2).clamp(16.0, 48.0) : 16.0;
                final double gapSlider = remainingHeight > 0 ? (gapUnit * 1.5).clamp(12.0, 40.0) : 12.0;
                final double gapBottom = remainingHeight > 0 ? (gapUnit * 1).clamp(12.0, 40.0) : 12.0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: gapTop),
                              isCompact 
                                ? SizedBox(
                                    height: 32.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ShadowingChallengeInstruction(color: theme.primaryColor),
                                    ),
                                  )
                                : ShadowingChallengeInstruction(color: theme.primaryColor),
                              SizedBox(height: gapInstruction),
                              
                              isCompact 
                                ? SizedBox(
                                    height: 90.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ShadowingChallengePromptCard(
                                        word: quest.word ?? "",
                                        ipa: quest.phonetic ?? "",
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                      ),
                                    ),
                                  )
                                : ShadowingChallengePromptCard(
                                    word: quest.word ?? "",
                                    ipa: quest.phonetic ?? "",
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                              SizedBox(height: gapPrompt),
                              
                              isCompact
                                ? SizedBox(
                                    height: 50.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ShadowingChallengeWaveformTrace(
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        isPreviewing: _isPreviewing,
                                        traceProgress: _traceProgress,
                                      ),
                                    ),
                                  )
                                : ShadowingChallengeWaveformTrace(
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    isPreviewing: _isPreviewing,
                                    traceProgress: _traceProgress,
                                  ),
                              SizedBox(height: gapSpeaker),
                              
                              isCompact
                                ? SizedBox(
                                    width: 80.r,
                                    height: 80.r,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ShadowingChallengePulseSpeaker(
                                        text: quest.textToSpeak ?? "",
                                        color: theme.primaryColor,
                                        onPlayTts: _playTts,
                                      ),
                                    ),
                                  )
                                : ShadowingChallengePulseSpeaker(
                                    text: quest.textToSpeak ?? "",
                                    color: theme.primaryColor,
                                    onPlayTts: _playTts,
                                  ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: gapSpeaker),
                              isCompact
                                ? SizedBox(
                                    height: 110.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ShadowingChallengeSpectralSlider(
                                        options: options,
                                        correctIndex: quest.correctAnswerIndex ?? 0,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        isAnswered: _isAnswered,
                                        selectedIndex: _selectedIndex,
                                        sliderValue: _sliderValue,
                                        onSubmitChoice: _submitChoice,
                                        onSliderUpdate: _onSliderUpdate,
                                        onSliderRelease: _onSliderRelease,
                                      ),
                                    ),
                                  )
                                : ShadowingChallengeSpectralSlider(
                                    options: options,
                                    correctIndex: quest.correctAnswerIndex ?? 0,
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    isAnswered: _isAnswered,
                                    selectedIndex: _selectedIndex,
                                    sliderValue: _sliderValue,
                                    onSubmitChoice: _submitChoice,
                                    onSliderUpdate: _onSliderUpdate,
                                    onSliderRelease: _onSliderRelease,
                                  ),
                              if (_isAnswered) ...[
                                SizedBox(height: gapSlider),
                                isCompact
                                  ? SizedBox(
                                      height: 110.h,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: ShadowingChallengeExplanationCard(
                                          quest: quest,
                                          color: theme.primaryColor,
                                          isDark: isDark,
                                          isCorrect: _isCorrect,
                                        ),
                                      ),
                                    )
                                  : ShadowingChallengeExplanationCard(
                                      quest: quest,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      isCorrect: _isCorrect,
                                    ),
                              ],
                              SizedBox(height: gapBottom),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
