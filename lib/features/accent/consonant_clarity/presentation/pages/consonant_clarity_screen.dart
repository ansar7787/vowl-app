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
import 'package:vowl/features/accent/consonant_clarity/presentation/widgets/consonant_clarity_instruction.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/widgets/consonant_clarity_prompt_card.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/widgets/consonant_clarity_pulse_speaker.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/widgets/consonant_clarity_tactile_grid.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/widgets/consonant_clarity_throat_indicator.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';

class ConsonantClarityScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConsonantClarityScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.consonantClarity,
  });

  @override
  State<ConsonantClarityScreen> createState() => _ConsonantClarityScreenState();
}

class _ConsonantClarityScreenState extends State<ConsonantClarityScreen>
    with AccentGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();

  AccentQuest? _lastQuest;

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);

  String? _shuffledQuestId;
  int _shuffledRetryCount = -1;
  List<String> _currentOptions = [];
  int _currentCorrectIndex = 0;

  void _ensureOptionsShuffled(AccentQuest quest, int retryCount) {
    if (_shuffledQuestId == quest.id && _shuffledRetryCount == retryCount) {
      return;
    }

    _shuffledQuestId = quest.id;
    _shuffledRetryCount = retryCount;

    final originalOptions = quest.options ?? ["A", "B"];
    final originalCorrectIndex = quest.correctAnswerIndex ?? 0;
    final originalCorrectAnswer =
        originalOptions.isNotEmpty &&
            originalCorrectIndex < originalOptions.length
        ? originalOptions[originalCorrectIndex]
        : null;

    _currentOptions = List.from(originalOptions)..shuffle();
    if (originalCorrectAnswer != null) {
      _currentCorrectIndex = _currentOptions.indexOf(originalCorrectAnswer);
    } else {
      _currentCorrectIndex = 0;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedIndex.dispose();
    disposeAccentGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initAccentGame();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  void _submitChoice(int index, int correct) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _selectedIndex.value = index;

    bool isCorrect = index == correct;

    if (isCorrect) {
      hapticService.selection();
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
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
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
            : _lastQuest;

        if (quest != null && !isAnsweredNotifier.value) {
          final currentLives = (state is AccentLoaded)
              ? state.livesRemaining
              : lastLives;
          _ensureOptionsShuffled(quest, currentLives ?? 3);
        }

        final options = _currentOptions.isEmpty
            ? (quest?.options ?? ["A", "B"])
            : _currentOptions;
        final correctIndex = _currentOptions.isEmpty
            ? (quest?.correctAnswerIndex ?? 0)
            : _currentCorrectIndex;
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
                          return RawScrollbar(
                            controller: _scrollController,
                            thumbColor: theme.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            radius: Radius.circular(8.r),
                            thickness: 4.w,
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics: (!isFirstStagePassedNotifier.value)
                                  ? const NeverScrollableScrollPhysics()
                                  : const BouncingScrollPhysics(),
                              slivers: [
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: IgnorePointer(
                                    ignoring: isFirstStagePassedNotifier.value,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24.w,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(height: 16.h),
                                          Semantics(
                                            liveRegion: true,
                                            child: ConsonantClarityInstruction(
                                              primaryColor: theme.primaryColor,
                                              instruction:
                                                  isFirstStagePassedNotifier
                                                      .value
                                                  ? "Great job! Now confirm by speaking the word."
                                                  : quest.instruction,
                                            ),
                                          ),
                                          const Spacer(),
                                          ConsonantClarityPromptCard(
                                            word: quest.word ?? "",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            isAnswered:
                                                isAnsweredNotifier.value ||
                                                isFirstStagePassedNotifier
                                                    .value,
                                          ),
                                          const Spacer(),
                                          if (isFirstStagePassedNotifier
                                                  .value &&
                                              quest.voicing != null &&
                                              quest.airflow != null)
                                            ConsonantClarityThroatIndicator(
                                              voicing: quest.voicing!,
                                              airflow: quest.airflow!,
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                            )
                                          else
                                            ConsonantClarityPulseSpeaker(
                                              text: quest.textToSpeak ?? "",
                                              color: theme.primaryColor,
                                              onPlayTts: _playTts,
                                            ),
                                          const Spacer(flex: 2),
                                          ConsonantClarityTactileGrid(
                                            options: options,
                                            correctIndex: correctIndex,
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            isAnswered:
                                                isAnsweredNotifier.value ||
                                                isFirstStagePassedNotifier
                                                    .value,
                                            selectedIndex: _selectedIndex.value,
                                            onSubmitChoice: _submitChoice,
                                          ),
                                          SizedBox(height: 24.h),
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
                                          ShadowPlaybackCompare(
                                            expectedText: quest.word ?? "",
                                            primaryColor: theme.primaryColor,
                                            isPositioned: false,
                                            onConfirmed: () {
                                              context.read<AccentBloc>().add(
                                                const AccentSpeakConfirmed(5),
                                              );
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
