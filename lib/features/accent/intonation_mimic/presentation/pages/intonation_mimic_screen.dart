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
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_instruction.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_prompt_card.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_rollercoaster.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_pulse_speaker.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_vertical_fader.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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

class _IntonationMimicScreenState extends State<IntonationMimicScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  AccentQuest? _lastQuest;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _sliderValue = 0.5;
  int? _selectedIndex;
  bool _isFirstStagePassed = false;

  // Pitch ride animation parameters
  double _cartPosition = 0.0;
  bool _isRiding = false;
  Timer? _rideTimer;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
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

  void _onSliderUpdate(
    double value,
    int correct,
    int topIndex,
    int bottomIndex,
  ) {
    if (_isAnswered || _isFirstStagePassed) return;
    setState(() => _sliderValue = value);

    // Auto-lock when reaching ends
    if (value < 0.1) {
      _submitChoice(bottomIndex, correct, topIndex, bottomIndex);
    } else if (value > 0.9) {
      _submitChoice(topIndex, correct, topIndex, bottomIndex);
    }
  }

  void _submitChoice(int index, int correct, int topIndex, int bottomIndex) {
    if (_isAnswered || _isFirstStagePassed) return;
    setState(() {
      _selectedIndex = index;
      _sliderValue = index == topIndex ? 1.0 : 0.0;
    });

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isFirstStagePassed = true;
      });
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          _lastQuest = state.currentQuest;
          final currentLives = state.livesRemaining;
          final livesChanged = _lastLives != null && currentLives > _lastLives!;

          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _sliderValue = 0.5;
              _selectedIndex = null;
              _cartPosition = 0.0;
              _isRiding = false;
              _isFirstStagePassed = false;
            });
            // Proactively auto-play sound and trigger ride effect on load
            final quest = state.currentQuest;
            if (quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                  _triggerRideEffect();
                }
              });
            }
          }
          _lastLives = currentLives;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CONTOUR MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest
            : _lastQuest;
        final List<String> options = List.from(quest?.options ?? ["A", "B"]);
        while (options.length < 2) {
          options.add("Unknown Option");
        }
        final contour = quest?.intonationMap ?? [1, 2, 1, 0];
        final mediaQuery = MediaQuery.of(context);

        int topIndex = options.indexWhere(
          (o) => o.toLowerCase().contains('rising'),
        );
        int bottomIndex = options.indexWhere(
          (o) => o.toLowerCase().contains('falling'),
        );
        if (topIndex == -1 && bottomIndex == -1) {
          topIndex = 1;
          bottomIndex = 0;
        } else if (topIndex == -1) {
          topIndex = bottomIndex == 0 ? 1 : 0;
        } else if (bottomIndex == -1) {
          bottomIndex = topIndex == 0 ? 1 : 0;
        }

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            useScrolling: false,
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final maxWidth = constraints.maxWidth;
                      final bool isCompact = maxHeight < 580;

                      final double estimatedContentHeight =
                          24.h + 70.h + 80.h + 140.h;
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 24.0)
                          : 8.0;
                      final double gapInstruction = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 24.0)
                          : 8.0;
                      final double gapPrompt = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(12.0, 32.0)
                          : 12.0;
                      final double gapSpeaker = remainingHeight > 0
                          ? (gapUnit * 2).clamp(16.0, 48.0)
                          : 16.0;
                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(height: gapTop),
                                            IntonationMimicInstruction(
                                              color: theme.primaryColor,
                                              instruction: _isFirstStagePassed
                                                  ? "Great job! Now record yourself saying the word."
                                                  : context.tr(
                                                      'games.intonation_mimic_instruction',
                                                      fallback:
                                                          "Identify the intonation",
                                                    ),
                                            ),
                                            SizedBox(height: gapInstruction),

                                            isCompact
                                                ? SizedBox(
                                                    height: 90.h,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: SizedBox(
                                                        width: maxWidth - 48.w,
                                                        child:
                                                            IntonationMimicPromptCard(
                                                              word: quest.word ?? "",
                                                              color: theme.primaryColor,
                                                              isDark: isDark,
                                                              emotionContext: quest.emotionContext,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                : IntonationMimicPromptCard(
                                                    word: quest.word ?? "",
                                                    color: theme.primaryColor,
                                                    isDark: isDark,
                                                    emotionContext: quest.emotionContext,
                                                  ),
                                            SizedBox(height: gapPrompt),

                                            if (_isAnswered ||
                                                _isFirstStagePassed) ...[
                                              IntonationMimicRollercoaster(
                                                contour: contour,
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                                isRiding: _isRiding,
                                                cartPosition: _cartPosition,
                                              ),
                                              SizedBox(height: gapSpeaker),
                                            ],

                                            IntonationMimicPulseSpeaker(
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
                                            IntonationMimicVerticalFader(
                                              options: options,
                                              correctIndex:
                                                  quest.correctAnswerIndex ?? 0,
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                              isAnswered:
                                                  _isAnswered || _isFirstStagePassed,
                                              selectedIndex: _selectedIndex,
                                              sliderValue: _sliderValue,
                                              topIndex: topIndex,
                                              bottomIndex: bottomIndex,
                                              onSubmitChoice: (idx, correct) =>
                                                  _submitChoice(
                                                    idx,
                                                    correct,
                                                    topIndex,
                                                    bottomIndex,
                                                  ),
                                              onSliderUpdate: (val, correct) =>
                                                  _onSliderUpdate(
                                                    val,
                                                    correct,
                                                    topIndex,
                                                    bottomIndex,
                                                  ),
                                            ),

                                            SizedBox(height: gapBottom),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isFirstStagePassed && !_isAnswered)
                                  SpeakToConfirmOverlay(
                                    expectedText: quest.word ?? "",
                                    displayText: "Speak the sentence with the correct intonation:\n${quest.word ?? ""}",
                                    primaryColor: theme.primaryColor,
                                    onConfirmed: () => _submitVerbalEvaluation(true),
                                    onSkipped: () => _submitVerbalEvaluation(false),
                                    isPositioned: false,
                                  ),
                                SizedBox(height: _isAnswered ? 180.h : 0),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
