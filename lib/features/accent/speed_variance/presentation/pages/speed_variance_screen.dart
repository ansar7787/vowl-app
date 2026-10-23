import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/mixins/accent_game_screen_mixin.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_instruction.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_prompt_card.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_pulse_speaker.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_tempo_dial.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_speed_toggle.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

class SpeedVarianceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeedVarianceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speedVariance,
  });

  @override
  State<SpeedVarianceScreen> createState() => _SpeedVarianceScreenState();
}

class _SpeedVarianceScreenState extends State<SpeedVarianceScreen>
    with
        GameScreenMixin<SpeedVarianceScreen>,
        AccentGameScreenMixin<SpeedVarianceScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  AccentQuest? _lastQuest;

  final ValueNotifier<double> _dialRotation = ValueNotifier(0.0);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);

  final ValueNotifier<bool> _isNaturalSpeed = ValueNotifier(true);
  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

  @override
  void initState() {
    super.initState();
    initAccentGame();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    _dialRotation.dispose();
    _isDragging.dispose();
    _selectedIndex.dispose();
    _isNaturalSpeed.dispose();
    try {
      soundService.stopTts();
    } catch (_) {}
    disposeAccentGame();
    super.dispose();
  }

  void _scrollToBottom() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _playTts(String text, {double? speed}) {
    hapticService.selection();
    soundService.playTts(text, speed: speed ?? 0.4);
  }

  double _lastHapticRotation = 0.0;

  void _onDialRotate(DragUpdateDetails details, int correct) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final double dx = details.delta.dx;
    final double dy = details.delta.dy;
    final double x = details.localPosition.dx;

    // A simplified, highly reliable rotation mapping:
    // Horizontal drags always map directly to rotation direction (drag right = turn right).
    // Vertical drags map based on which half of the dial is touched.
    final bool isLeftHalf = x < 50.r;
    final double vRot = isLeftHalf ? -dy : dy;

    final double totalRot = (dx + vRot) / 30.0;

    _isDragging.value = true;
    _dialRotation.value = (_dialRotation.value + totalRot).clamp(-1.0, 1.0);

    if ((_dialRotation.value - _lastHapticRotation).abs() > 0.15) {
      hapticService.selection();
      _lastHapticRotation = _dialRotation.value;
    }

    // Auto-lock when reaching ends
    if (_dialRotation.value < -0.8) {
      _submitChoice(0, correct);
    } else if (_dialRotation.value > 0.8) {
      _submitChoice(1, correct);
    }
  }

  void _onDialRelease() {
    if (isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        !_isDragging.value) {
      return;
    }
    _isDragging.value = false;
    final currentQuest =
        _lastQuest ??
        ((context.read<AccentBloc>().state is AccentLoaded)
            ? (context.read<AccentBloc>().state as AccentLoaded).currentQuest
            : null);
    final int correct = currentQuest?.correctAnswerIndex ?? 0;

    if (_dialRotation.value < -0.3) {
      _submitChoice(0, correct);
    } else if (_dialRotation.value > 0.3) {
      _submitChoice(1, correct);
    } else if (!isAnsweredNotifier.value) {
      _dialRotation.value = 0.0;
    }
  }

  void _submitChoice(int index, int correct) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _selectedIndex.value = index;
    _dialRotation.value = index == 0 ? -0.8 : 0.8;
    _isDragging.value = false;

    bool isCorrect = index == correct;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _timerKey.currentState?.stop();
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _timerKey.currentState?.stop();
      final currentQuest =
          _lastQuest ??
          ((context.read<AccentBloc>().state is AccentLoaded)
              ? (context.read<AccentBloc>().state as AccentLoaded).currentQuest
              : null);
      if (currentQuest != null) {
        final options = currentQuest.options ?? [];
        submitWrongAnswer(
          quest: currentQuest,
          userAnswer: index < options.length ? options[index] : '',
        );
      } else {
        hapticService.error();
        soundService.playWrong();
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = false;
        context.read<AccentBloc>().add(const SubmitAnswer(false));
      }
      _scrollToBottom();
    }
  }

  void _handleTimeExpired() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    final currentQuest =
        _lastQuest ??
        ((context.read<AccentBloc>().state is AccentLoaded)
            ? (context.read<AccentBloc>().state as AccentLoaded).currentQuest
            : null);
    if (currentQuest != null) {
      submitWrongAnswer(quest: currentQuest, userAnswer: '[Timeout]');
    } else {
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<AccentBloc>().add(const SubmitAnswer(false));
    }
    _scrollToBottom();
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
      submitCorrectAnswer();
      _scrollToBottom();
    } else {
      final currentQuest =
          _lastQuest ??
          ((context.read<AccentBloc>().state is AccentLoaded)
              ? (context.read<AccentBloc>().state as AccentLoaded).currentQuest
              : null);
      if (currentQuest != null) {
        submitWrongAnswer(quest: currentQuest, userAnswer: '');
      } else {
        hapticService.error();
        soundService.playWrong();
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = false;
        context.read<AccentBloc>().add(const SubmitAnswer(false));
      }
      _scrollToBottom();
    }
  }

  @override
  void onQuestionReset() {
    _dialRotation.value = 0.0;

    _isDragging.value = false;

    _selectedIndex.value = null;

    _isNaturalSpeed.value = true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listenWhen: accentListenWhen,
      listener: onAccentStateChanged,
      builder: (context, state) {
        if (state is AccentLoaded) {
          _lastQuest = state.currentQuest;
        }
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest
            : _lastQuest;

        final options = quest?.options ?? [];
        final hasValidQuest = quest != null && options.length >= 2;

        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
              isFirstStagePassedNotifier,
            ]),
            builder: (context, _) {
              return AccentBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                showConfetti: showConfettiNotifier.value,
                onContinue: () =>
                    context.read<AccentBloc>().add(const NextQuestion()),
                onHint: () {},
                useScrolling: false,
                child: !hasValidQuest
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isFirstStagePassed =
                        isFirstStagePassedNotifier.value;
                    final bool isAnswered = isAnsweredNotifier.value;
                    final maxHeight = constraints.maxHeight;
                    final double estimatedContentHeight =
                        24.h + 90.h + 80.h + 140.h;
                    final remainingHeight = maxHeight - estimatedContentHeight;

                    final double gapUnit = remainingHeight > 0
                        ? remainingHeight / 8
                        : 0;
                    final double gapTop = remainingHeight > 0
                        ? (gapUnit * 1).clamp(8.0, 24.0)
                        : 8.0;
                    final double gapInstruction = remainingHeight > 0
                        ? (gapUnit * 1).clamp(12.0, 24.0)
                        : 12.0;
                    final double gapPrompt = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(12.0, 32.0)
                        : 12.0;
                    final double gapSpeaker = remainingHeight > 0
                        ? (gapUnit * 2).clamp(16.0, 48.0)
                        : 16.0;

                    final double gapBottom = remainingHeight > 0
                        ? (gapUnit * 1).clamp(12.0, 40.0)
                        : 12.0;

                    return RawScrollbar(
                      controller: _scrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                    ),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: 420.w,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(height: gapTop),
                                                if (!isFirstStagePassed &&
                                                    !isAnswered)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom: 16.h,
                                                    ),
                                                    child: SpeedChallengeTimer(
                                                      key: _timerKey,
                                                      durationSeconds: 15,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      onTimeUp:
                                                          _handleTimeExpired,
                                                    ),
                                                  ),
                                                SpeedVarianceInstruction(
                                                  color: theme.primaryColor,
                                                  instruction:
                                                      isFirstStagePassed
                                                      ? "Great job! Now record yourself saying the sentence."
                                                      : quest.instruction,
                                                ),
                                                SizedBox(
                                                  height: gapInstruction,
                                                ),
                                                SpeedVariancePromptCard(
                                                  word: quest.word ?? "",
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                ),
                                                SizedBox(height: gapPrompt),
                                                if (isFirstStagePassed &&
                                                    !isAnswered)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom: 16.h,
                                                    ),
                                                    child: ValueListenableBuilder<bool>(
                                                      valueListenable:
                                                          _isNaturalSpeed,
                                                      builder: (context, isNatural, _) {
                                                        return SpeedVarianceSpeedToggle(
                                                          isNatural: isNatural,
                                                          onChanged: (val) {
                                                            _isNaturalSpeed
                                                                    .value =
                                                                val;
                                                            _playTts(
                                                              quest.textToSpeak ??
                                                                  "",
                                                              speed: val
                                                                  ? (quest.naturalSpeed ??
                                                                        1.0)
                                                                  : (quest.clearSpeed ??
                                                                        0.75),
                                                            );
                                                          },
                                                          primaryColor: theme
                                                              .primaryColor,
                                                          isDark: isDark,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ValueListenableBuilder<bool>(
                                                  valueListenable:
                                                      _isNaturalSpeed,
                                                  builder: (context, isNatural, _) {
                                                    return SpeedVariancePulseSpeaker(
                                                      text:
                                                          quest.textToSpeak ??
                                                          "",
                                                      color: theme.primaryColor,
                                                      onPlayTts: (text) => _playTts(
                                                        text,
                                                        speed:
                                                            isFirstStagePassed
                                                            ? (isNatural
                                                                  ? (quest.naturalSpeed ??
                                                                        1.0)
                                                                  : (quest.clearSpeed ??
                                                                        0.75))
                                                            : quest.targetSpeed,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(height: gapSpeaker),
                                                ListenableBuilder(
                                                  listenable: Listenable.merge([
                                                    _dialRotation,
                                                    _isDragging,
                                                    _selectedIndex,
                                                  ]),
                                                  builder: (context, _) {
                                                    return IgnorePointer(
                                                      ignoring:
                                                          isFirstStagePassed ||
                                                          isAnswered,
                                                      child: SpeedVarianceTempoDial(
                                                        options: options,
                                                        correctIndex:
                                                            quest
                                                                .correctAnswerIndex ??
                                                            0,
                                                        color:
                                                            theme.primaryColor,
                                                        isDark: isDark,
                                                        isAnswered:
                                                            isAnswered ||
                                                            isFirstStagePassed,
                                                        isDragging:
                                                            _isDragging.value,
                                                        dialRotation:
                                                            _dialRotation.value,
                                                        selectedIndex:
                                                            _selectedIndex
                                                                .value,
                                                        onDialRotate:
                                                            _onDialRotate,
                                                        onDialRelease:
                                                            _onDialRelease,
                                                        onSubmitChoice:
                                                            _submitChoice,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                SizedBox(height: gapBottom),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isFirstStagePassed && !isAnswered)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: 420.w,
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(height: 24.h),
                                        SpeakToConfirmOverlay(
                                          key: const ValueKey(
                                            'speak_to_confirm_overlay',
                                          ),
                                          expectedText:
                                              quest.textToSpeak ??
                                              quest.word ??
                                              "",
                                          primaryColor: theme.primaryColor,
                                          isPositioned: false,
                                          onConfirmed: () =>
                                              _submitVerbalEvaluation(true),
                                          onSkipped: () =>
                                              _submitVerbalEvaluation(false),
                                        ),
                                        SizedBox(height: 48.h),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
