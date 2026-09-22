import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/mixins/accent_game_screen_mixin.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_instruction.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_prompt_card.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_rollercoaster.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_pulse_speaker.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_vertical_fader.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

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
    with TickerProviderStateMixin, AccentGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  AccentQuest? _lastQuest;
  final ValueNotifier<double> _sliderValue = ValueNotifier(0.5);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);

  final ValueNotifier<double> _cartPosition = ValueNotifier(0.0);
  final ValueNotifier<bool> _isRiding = ValueNotifier(false);
  Timer? _rideTimer;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initAccentGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rideTimer?.cancel();
    _cartPosition.dispose();
    _isRiding.dispose();
    _selectedIndex.dispose();
    _sliderValue.dispose();
    disposeAccentGame();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
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
    hapticService.selection();
    soundService.playTts(text);
    _triggerRideEffect();
  }

  void _triggerRideEffect() {
    _rideTimer?.cancel();
    _cartPosition.value = 0.0;
    _isRiding.value = true;

    const steps = 30;
    const interval = Duration(milliseconds: 40);
    int currentStep = 0;

    _rideTimer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      _cartPosition.value = (currentStep / steps).clamp(0.0, 1.0);

      if (currentStep >= steps) {
        timer.cancel();
        _isRiding.value = false;
      }
    });
  }

  void _onSliderUpdate(
    double value,
    int correct,
    int topIndex,
    int bottomIndex,
  ) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _sliderValue.value = value;

    // Auto-lock when reaching ends
    if (value < 0.1) {
      _submitChoice(bottomIndex, correct, topIndex, bottomIndex);
    } else if (value > 0.9) {
      _submitChoice(topIndex, correct, topIndex, bottomIndex);
    }
  }

  void _submitChoice(int index, int correct, int topIndex, int bottomIndex) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _selectedIndex.value = index;
    _sliderValue.value = index == topIndex ? 1.0 : 0.0;

    bool isCorrect = index == correct;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _sliderValue.value = 0.5;

    _selectedIndex.value = null;

    _cartPosition.value = 0.0;

    _isRiding.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listenWhen: accentListenWhen,
      listener: onAccentStateChanged,
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
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
              _selectedIndex,
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
                    context.read<AccentBloc>().add(NextQuestion()),
                onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
                useScrolling: false,
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
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

                          return RawScrollbar(
                            controller: _scrollController,
                            thumbColor: theme.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            radius: Radius.circular(8.r),
                            thickness: 4.w,
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics:
                                  (!isFirstStagePassedNotifier.value &&
                                      remainingHeight > 50)
                                  ? const NeverScrollableScrollPhysics()
                                  : const BouncingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: IgnorePointer(
                                    ignoring: isFirstStagePassedNotifier.value,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24.w,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: gapTop),
                                                    IntonationMimicInstruction(
                                                      color: theme.primaryColor,
                                                      instruction:
                                                          isFirstStagePassedNotifier
                                                              .value
                                                          ? "Great job! Now record yourself saying the word."
                                                          : quest.instruction,
                                                    ),
                                                    SizedBox(
                                                      height: gapInstruction,
                                                    ),

                                                    isCompact
                                                        ? SizedBox(
                                                            height: 90.h,
                                                            child: FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: SizedBox(
                                                                width:
                                                                    maxWidth -
                                                                    48.w,
                                                                child: IntonationMimicPromptCard(
                                                                  word:
                                                                      quest
                                                                          .word ??
                                                                      "",
                                                                  color: theme
                                                                      .primaryColor,
                                                                  isDark:
                                                                      isDark,
                                                                  emotionContext:
                                                                      quest
                                                                          .emotionContext,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : IntonationMimicPromptCard(
                                                            word:
                                                                quest.word ??
                                                                "",
                                                            color: theme
                                                                .primaryColor,
                                                            isDark: isDark,
                                                            emotionContext: quest
                                                                .emotionContext,
                                                          ),
                                                    SizedBox(height: gapPrompt),

                                                    if (isAnsweredNotifier
                                                            .value ||
                                                        isFirstStagePassedNotifier
                                                            .value) ...[
                                                      ValueListenableBuilder<
                                                        bool
                                                      >(
                                                        valueListenable:
                                                            _isRiding,
                                                        builder: (context, isRiding, _) {
                                                          return ValueListenableBuilder<
                                                            double
                                                          >(
                                                            valueListenable:
                                                                _cartPosition,
                                                            builder:
                                                                (
                                                                  context,
                                                                  cartPosition,
                                                                  _,
                                                                ) {
                                                                  return IntonationMimicRollercoaster(
                                                                    contour:
                                                                        contour,
                                                                    color: theme
                                                                        .primaryColor,
                                                                    isDark:
                                                                        isDark,
                                                                    isRiding:
                                                                        isRiding,
                                                                    cartPosition:
                                                                        cartPosition,
                                                                  );
                                                                },
                                                          );
                                                        },
                                                      ),
                                                      SizedBox(
                                                        height: gapSpeaker,
                                                      ),
                                                    ],

                                                    IntonationMimicPulseSpeaker(
                                                      text:
                                                          quest.textToSpeak ??
                                                          "",
                                                      color: theme.primaryColor,
                                                      onPlayTts: _playTts,
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: gapSpeaker,
                                                    ),
                                                    ValueListenableBuilder<
                                                      double
                                                    >(
                                                      valueListenable:
                                                          _sliderValue,
                                                      builder: (context, sliderValue, _) {
                                                        return IntonationMimicVerticalFader(
                                                          options: options,
                                                          correctIndex:
                                                              quest
                                                                  .correctAnswerIndex ??
                                                              0,
                                                          color: theme
                                                              .primaryColor,
                                                          isDark: isDark,
                                                          isAnswered:
                                                              isAnsweredNotifier
                                                                  .value ||
                                                              isFirstStagePassedNotifier
                                                                  .value,
                                                          selectedIndex:
                                                              _selectedIndex
                                                                  .value,
                                                          sliderValue:
                                                              sliderValue,
                                                          topIndex: topIndex,
                                                          bottomIndex:
                                                              bottomIndex,
                                                          onSubmitChoice:
                                                              (idx, correct) =>
                                                                  _submitChoice(
                                                                    idx,
                                                                    correct,
                                                                    topIndex,
                                                                    bottomIndex,
                                                                  ),
                                                          onSliderUpdate:
                                                              (val, correct) =>
                                                                  _onSliderUpdate(
                                                                    val,
                                                                    correct,
                                                                    topIndex,
                                                                    bottomIndex,
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

                                          SizedBox(
                                            height:
                                                (isFirstStagePassedNotifier
                                                        .value &&
                                                    !isAnsweredNotifier.value)
                                                ? 40.h
                                                : 160.h,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                if (isFirstStagePassedNotifier.value &&
                                    !isAnsweredNotifier.value)
                                  SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        if (isFirstStagePassedNotifier.value &&
                                            !isAnsweredNotifier.value)
                                          SpeakToConfirmOverlay(
                                            expectedText: quest.word ?? "",
                                            displayText:
                                                "Speak the sentence with the correct intonation:\n${quest.word ?? ""}",
                                            primaryColor: theme.primaryColor,
                                            onConfirmed: () =>
                                                _submitVerbalEvaluation(true),
                                            onSkipped: () =>
                                                _submitVerbalEvaluation(false),
                                            isPositioned: false,
                                          ),

                                        SizedBox(height: 60.h),
                                      ],
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
