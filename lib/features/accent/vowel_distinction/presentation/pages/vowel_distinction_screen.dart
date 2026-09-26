import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/mixins/accent_game_screen_mixin.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_instruction.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_prompt_card.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_pulse_speaker.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_spectral_slider.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_trapezoid_chart.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class VowelDistinctionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const VowelDistinctionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.vowelDistinction,
  });

  @override
  State<VowelDistinctionScreen> createState() => _VowelDistinctionScreenState();
}

class _VowelDistinctionScreenState extends State<VowelDistinctionScreen>
    with
        GameScreenMixin<VowelDistinctionScreen>,
        AccentGameScreenMixin<VowelDistinctionScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<double> _sliderValue = ValueNotifier(0.5);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);

  Timer? _mismatchResetTimer;
  Timer? _autoplayTimer;

  @override
  void initState() {
    super.initState();
    initAccentGame();
  }

  @override
  void dispose() {
    _mismatchResetTimer?.cancel();
    _autoplayTimer?.cancel();
    _scrollController.dispose();
    _sliderValue.dispose();
    _selectedIndex.dispose();
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
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _onSliderUpdate(double value, int correct) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _sliderValue.value = value;

    // Auto-lock when reaching ends
    if (value < 0.1) {
      _submitChoice(0, correct);
    } else if (value > 0.9) {
      _submitChoice(1, correct);
    }
  }

  void _submitChoice(int index, int correct) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _selectedIndex.value = index;
    _sliderValue.value = index == 0 ? 0.0 : 1.0;

    bool isCorrect = index == correct;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Do NOT submit yet. Wait for Phase 2.
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _sliderValue.value = 0.5;

    _selectedIndex.value = null;
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
            ? state.currentQuest as AccentQuest?
            : null;
        final options = quest?.options ?? ["A", "B"];
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
                    context.read<AccentBloc>().add(NextQuestion()),
                onHint: () =>
                    context.read<AccentBloc>().add(const AccentHintUsed()),
                useScrolling: false,
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final maxHeight = constraints.maxHeight;
                          final bool isCompact = maxHeight < 580;

                          final double estimatedContentHeight =
                              24.h +
                              (isCompact ? 90.h : 120.h) +
                              100.h +
                              (isCompact ? 130.h : 172.h);
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

                          Widget buildSlider() {
                            return ListenableBuilder(
                              listenable: Listenable.merge([
                                _sliderValue,
                                _selectedIndex,
                              ]),
                              builder: (context, _) {
                                return VowelDistinctionSpectralSlider(
                                  options: options,
                                  correctIndex: quest.correctAnswerIndex ?? 0,
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                  isAnswered:
                                      isAnsweredNotifier.value ||
                                      isFirstStagePassedNotifier.value,
                                  selectedIndex: _selectedIndex.value,
                                  sliderValue: _sliderValue.value,
                                  onSubmitChoice: _submitChoice,
                                  onSliderUpdate: _onSliderUpdate,
                                  onSliderEnd: (value, correct) {
                                    if (isAnsweredNotifier.value ||
                                        isFirstStagePassedNotifier.value) {
                                      return;
                                    }
                                    if (value > 0.1 && value < 0.9) {
                                      _sliderValue.value =
                                          0.5; // Snap back to center if not committed
                                    }
                                  },
                                );
                              },
                            );
                          }

                          String getInstruction() {
                            if (isFirstStagePassedNotifier.value) {
                              return "Great job! Now confirm by speaking the word.";
                            }
                            return quest.instruction;
                          }

                          return RawScrollbar(
                            controller: _scrollController,
                            thumbColor: theme.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            radius: Radius.circular(8.r),
                            thickness: 4.w,
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
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
                                                    VowelDistinctionInstruction(
                                                      color: theme.primaryColor,
                                                      instruction:
                                                          getInstruction(),
                                                    ),
                                                    SizedBox(
                                                      height: gapInstruction,
                                                    ),
                                                    VowelDistinctionPromptCard(
                                                      word: quest.word ?? "",
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                    SizedBox(height: gapPrompt),
                                                    if (isFirstStagePassedNotifier
                                                            .value &&
                                                        quest.vowelChart !=
                                                            null)
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              bottom: 24.h,
                                                            ),
                                                        child:
                                                            VowelTrapezoidChart(
                                                              vowelChart: quest
                                                                  .vowelChart!,
                                                              color: theme
                                                                  .primaryColor,
                                                              isDark: isDark,
                                                            ),
                                                      )
                                                    else
                                                      VowelDistinctionPulseSpeaker(
                                                        text:
                                                            quest.textToSpeak ??
                                                            "",
                                                        color:
                                                            theme.primaryColor,
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
                                                    buildSlider(),
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
                                        SpeakToConfirmOverlay(
                                          expectedText:
                                              quest.textToSpeak ??
                                              quest.word ??
                                              "",
                                          primaryColor: theme.primaryColor,
                                          isPositioned: false,
                                          onConfirmed: () {
                                            context.read<AccentBloc>().add(
                                              const AccentSpeakConfirmed(5),
                                            );
                                            _submitVerbalEvaluation(true);
                                          },
                                          onSkipped: () =>
                                              _submitVerbalEvaluation(false),
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
