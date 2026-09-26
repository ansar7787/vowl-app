import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/mixins/accent_game_screen_mixin.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_feedback_panel.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_drill_instruction.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_drill_hologram_console.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_drill_region_map.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';

class DialectDrillScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DialectDrillScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dialectDrill,
  });

  @override
  State<DialectDrillScreen> createState() => _DialectDrillScreenState();
}

class _DialectDrillScreenState extends State<DialectDrillScreen>
    with
        GameScreenMixin<DialectDrillScreen>,
        AccentGameScreenMixin<DialectDrillScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  AccentQuest? _lastQuest;

  List<String>? _shuffledOptions;
  int? _shuffledCorrectIndex;

  late final ScrollController _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initAccentGame();
  }

  void _shuffleOptions(AccentQuest? quest) {
    if (quest == null || quest.options == null) return;
    List<MapEntry<int, String>> indexedOptions = quest.options!
        .asMap()
        .entries
        .toList();
    indexedOptions.shuffle();
    _shuffledOptions = indexedOptions.map((e) => e.value).toList();
    _shuffledCorrectIndex = indexedOptions.indexWhere(
      (e) => e.key == (quest.correctAnswerIndex ?? 0),
    );
  }

  void _triggerAutoPlay(AccentQuest quest) {
    final instruction = quest.instruction.toLowerCase();
    final String targetLocale = instruction.contains('british')
        ? "en-GB"
        : "en-US";
    soundService.playTts(quest.word ?? "", locale: targetLocale);
  }

  void _submitAnswer(int index, int correct, double maxWidth) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
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
      _scrollToBottom();
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listenWhen: accentListenWhen,
      listener: onAccentStateChanged,
      builder: (context, state) {
        final AccentQuest? originalQuest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;

        if (originalQuest != null &&
            _shuffledOptions == null &&
            !isAnsweredNotifier.value) {
          _shuffleOptions(originalQuest);
        }

        final AccentQuest? quest = originalQuest?.copyWith(
          options: _shuffledOptions,
          correctAnswerIndex: _shuffledCorrectIndex,
        );

        String instructionText = quest?.instruction ?? "";

        String brPr = "";
        String amPr = "";
        if (quest != null && quest.options != null) {
          for (var opt in quest.options!) {
            if (opt.contains('(British)')) {
              brPr = opt.replaceAll(' (British)', '');
            } else if (opt.contains('(American)')) {
              amPr = opt.replaceAll(' (American)', '');
            }
          }
        }
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
                onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
                useScrolling: false,
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : LayoutBuilder(
                        builder: (context, constraints) {
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
                                      !isAnsweredNotifier.value)
                                  ? const NeverScrollableScrollPhysics()
                                  : const BouncingScrollPhysics(),
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
                                            horizontal: 16.w,
                                            vertical: 24.h,
                                          ),
                                          child: IgnorePointer(
                                            ignoring: isFirstStagePassedNotifier
                                                .value,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    DialectDrillInstruction(
                                                      instruction:
                                                          isFirstStagePassedNotifier
                                                              .value
                                                          ? "Great job! Now record yourself saying the word."
                                                          : instructionText,
                                                      accentColor:
                                                          theme.primaryColor,
                                                    ),
                                                    if (quest.dialectRegion !=
                                                        null) ...[
                                                      SizedBox(height: 16.h),
                                                      DialectDrillRegionMap(
                                                        region: quest
                                                            .dialectRegion!,
                                                        color:
                                                            theme.primaryColor,
                                                        isDark: isDark,
                                                      ),
                                                    ],
                                                    SizedBox(height: 24.h),
                                                    DialectDrillHologramConsole(
                                                      quest: quest,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          isAnsweredNotifier
                                                              .value ||
                                                          isFirstStagePassedNotifier
                                                              .value,
                                                      isCorrect:
                                                          isFirstStagePassedNotifier
                                                              .value
                                                          ? true
                                                          : isCorrectNotifier
                                                                .value,
                                                      onPlayTargetAudio: () =>
                                                          _triggerAutoPlay(
                                                            quest,
                                                          ),
                                                      onSubmitAnswer:
                                                          _submitAnswer,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          curve: Curves.easeOut,
                                          child:
                                              (isAnsweredNotifier.value ||
                                                  isFirstStagePassedNotifier
                                                      .value)
                                              ? Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.w,
                                                  ).copyWith(bottom: 24.h),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Builder(
                                                        builder: (context) {
                                                          final bool isSuccess =
                                                              isCorrectNotifier
                                                                      .value ==
                                                                  true ||
                                                              isFirstStagePassedNotifier
                                                                  .value;
                                                          final bool
                                                          isFinalFailure =
                                                              (state
                                                                  is AccentGameOver) ||
                                                              (state is AccentLoaded &&
                                                                  state.isFinalFailure);
                                                          final bool
                                                          showExplanation =
                                                              isSuccess ||
                                                              isFinalFailure;
                                                          return DialectFeedbackPanel(
                                                            isCorrect:
                                                                isCorrectNotifier
                                                                    .value ??
                                                                isFirstStagePassedNotifier
                                                                    .value,
                                                            word:
                                                                quest.word ??
                                                                "",
                                                            britishPronunciation:
                                                                brPr.isEmpty
                                                                ? (quest.word ??
                                                                      "")
                                                                : brPr,
                                                            americanPronunciation:
                                                                amPr.isEmpty
                                                                ? (quest.word ??
                                                                      "")
                                                                : amPr,
                                                            hint:
                                                                null, // Replaced by SnackBar
                                                            explanation:
                                                                showExplanation
                                                                ? quest
                                                                      .explanation
                                                                : null,
                                                            dialectNote:
                                                                !showExplanation
                                                                ? quest
                                                                      .dialectNote
                                                                : null,
                                                            isDark: isDark,
                                                            isMidnight: false,
                                                            onPlayAudio:
                                                                (text, locale) {
                                                                  soundService
                                                                      .playTts(
                                                                        text,
                                                                        locale:
                                                                            locale,
                                                                      );
                                                                },
                                                          );
                                                        },
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            (isFirstStagePassedNotifier
                                                                    .value &&
                                                                !isAnsweredNotifier
                                                                    .value)
                                                            ? 40.h
                                                            : 160.h,
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : SizedBox(
                                                  width: double.infinity,
                                                  height:
                                                      (isFirstStagePassedNotifier
                                                              .value &&
                                                          !isAnsweredNotifier
                                                              .value)
                                                      ? 40.h
                                                      : 160.h,
                                                ),
                                        ),
                                      ],
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
                                          ShadowPlaybackCompare(
                                            expectedText: quest.word ?? "",
                                            primaryColor: theme.primaryColor,
                                            isPositioned: false,
                                            onConfirmed: () {
                                              _submitVerbalEvaluation(true);
                                            },
                                            onSkipped: () {
                                              _submitVerbalEvaluation(false);
                                            },
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
