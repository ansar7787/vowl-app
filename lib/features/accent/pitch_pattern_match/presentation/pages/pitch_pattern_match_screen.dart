import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_instruction.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_prompt_card.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_melodic_canvas.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_pulse_speaker.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_vertical_fader.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

class PitchPatternMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PitchPatternMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pitchPatternMatch,
  });

  @override
  State<PitchPatternMatchScreen> createState() =>
      _PitchPatternMatchScreenState();
}

class _PitchPatternMatchScreenState extends State<PitchPatternMatchScreen> {
  final ScrollController _scrollController = ScrollController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int _lastLives = AccentGameConstants.maxLives;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<double> _sliderValue = ValueNotifier(0.5);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  AccentQuest? _lastQuest;

  final ValueNotifier<double> _previewProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isPreviewing = ValueNotifier(false);
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _scrollController.dispose();
    _previewProgress.dispose();
    _isPreviewing.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _sliderValue.dispose();
    _selectedIndex.dispose();
    _isFirstStagePassed.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
    _triggerPreviewWave();
  }

  void _triggerPreviewWave() {
    _previewTimer?.cancel();
    _previewProgress.value = 0.0;
    _isPreviewing.value = true;

    const steps = 30;
    const interval = Duration(milliseconds: 40);
    int currentStep = 0;

    _previewTimer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      _previewProgress.value = (currentStep / steps).clamp(0.0, 1.0);
      
      if (currentStep >= steps) {
        timer.cancel();
        _isPreviewing.value = false;
      }
    });
  }

  void _onSliderUpdate(double value, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _sliderValue.value = value;

    // Auto-lock when reaching ends:
    // With quarterTurns: 3, 1.0 is top and 0.0 is bottom.
    if (value > 0.9) {
      _submitChoice(0, correct); // Select top card (index 0)
    } else if (value < 0.1) {
      _submitChoice(1, correct); // Select bottom card (index 1)
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedIndex.value = index;
    _sliderValue.value = index == 0 ? 1.0 : 0.0;

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isFirstStagePassed.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

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
          final livesChanged = (state.livesRemaining > _lastLives);
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _sliderValue.value = 0.5;
            _selectedIndex.value = null;
            _isFirstStagePassed.value = false;
            _previewProgress.value = 0.0;
            _isPreviewing.value = false;
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null) {
              _lastQuest = quest;
            }
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(const Duration(milliseconds: 500), () {
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
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'MELODY SYNCER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;
        final options = quest?.options ?? ["A", "B"];
        final pattern = quest?.pitchPatterns ?? [0, 1, 2, 1, 0];
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _sliderValue, _selectedIndex, _isFirstStagePassed]),
            builder: (context, _) {
              return AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            useScrolling: false,
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;

                      final double estimatedContentHeight =
                          24.h + 70.h + 80.h + 140.h;
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
                          : 0;

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
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
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
                                            PitchPatternMatchInstruction(
                                              color: theme.primaryColor,
                                              instruction: _isFirstStagePassed.value
                                                  ? "Great job! Now record yourself saying the word."
                                                  : context.tr(
                                                      'games.pitch_pattern_match_instruction',
                                                      fallback:
                                                          'Identify the pitch pattern',
                                                    ),
                                            ),
                                            SizedBox(height: gapInstruction),

                                            PitchPatternMatchPromptCard(
                                              word: quest.word ?? "",
                                              emotionContext: quest.emotionContext,
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                            ),
                                            SizedBox(height: gapPrompt),

                                            if (_isAnswered.value ||
                                                _isFirstStagePassed.value) ...[
                                              ValueListenableBuilder<bool>(
                                                valueListenable: _isPreviewing,
                                                builder: (context, isPreviewing, _) {
                                                  return ValueListenableBuilder<double>(
                                                    valueListenable: _previewProgress,
                                                    builder: (context, previewProgress, _) {
                                                      return PitchPatternMatchMelodicCanvas(
                                                        pattern: pattern,
                                                        color: theme.primaryColor,
                                                        isDark: isDark,
                                                        isPreviewing: isPreviewing,
                                                        isAnswered: _isAnswered.value || _isFirstStagePassed.value,
                                                        previewProgress: previewProgress,
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              SizedBox(height: gapSpeaker),
                                            ],

                                            PitchPatternMatchPulseSpeaker(
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
                                            PitchPatternMatchVerticalFader(
                                              options: options,
                                              correctIndex:
                                                  quest.correctAnswerIndex ?? 0,
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                              isAnswered:
                                                  _isAnswered.value || _isFirstStagePassed.value,
                                              selectedIndex: _selectedIndex.value,
                                              sliderValue: _sliderValue.value,
                                              onSubmitChoice: _submitChoice,
                                              onSliderUpdate: _onSliderUpdate,
                                            ),
                                            SizedBox(height: gapBottom),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isFirstStagePassed.value && !_isAnswered.value)
                                  SpeakToConfirmOverlay(
                                    expectedText: quest.textToSpeak ?? quest.word ?? "",
                                    primaryColor: theme.primaryColor,
                                    isPositioned: false,
                                    onConfirmed: () {
                                      _submitVerbalEvaluation(true);
                                    },
                                    onSkipped: () {
                                      _submitVerbalEvaluation(false);
                                    },
                                  ),
                                SizedBox(height: (_isAnswered.value || _isFirstStagePassed.value) ? 140.h : 0),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              );
            },
          ),
        );
      },
    );
  }
}
