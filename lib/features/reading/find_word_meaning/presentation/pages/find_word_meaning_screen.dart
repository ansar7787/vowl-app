import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/mixins/reading_game_screen_mixin.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_instruction.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_question_header.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_interactive_passage.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/context_sentence_builder.dart';
import 'package:vowl/core/services/error_journal_collector.dart';

class FindWordMeaningScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FindWordMeaningScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.findWordMeaning,
  });

  @override
  State<FindWordMeaningScreen> createState() => _FindWordMeaningScreenState();
}

class _FindWordMeaningScreenState extends State<FindWordMeaningScreen>
    with
        GameScreenMixin<FindWordMeaningScreen>,
        ReadingGameScreenMixin<FindWordMeaningScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final _scrollController = ScrollController();

  final ValueNotifier<bool> _showSentenceBuilder = ValueNotifier(false);
  final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    initReadingGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showSentenceBuilder.dispose();
    _pendingSelectedIndex.dispose();
    disposeReadingGame();
    super.dispose();
  }

  void _submitFinalAnswer(bool isCorrect, int index, [ReadingQuest? quest]) {
    if (_showSentenceBuilder.value || _pendingSelectedIndex.value != null) {
      return;
    }

    _pendingSelectedIndex.value = index;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      _showSentenceBuilder.value = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      hapticService.error();
      soundService.playWrong();

      if (quest != null) {
        ErrorJournalCollector.record(
          userId: 'local',
          gameType: widget.gameType.name,
          question: quest.question ?? InstructionHelper.getInstruction(quest),
          userAnswer: 'Incorrect meaning selected',
          correctAnswer: quest.correctAnswer ?? '',
          level: widget.level,
        );
      }
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _onSentenceBuilderComplete() {
    _showSentenceBuilder.value = false;
    context.read<ReadingBloc>().add(const SubmitAnswer(true));
  }

  @override
  void onQuestionReset() {
    _showSentenceBuilder.value = false;

    _pendingSelectedIndex.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: onReadingStateChanged,
      builder: (context, state) {
        final isLoaded = state is ReadingLoaded;
        final ReadingQuest? quest = isLoaded
            ? state.currentQuest as ReadingQuest?
            : null;
        final bool isAnsweredBloc = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrectBloc = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            showConfettiNotifier,
            _showSentenceBuilder,
            _pendingSelectedIndex,
          ]),
          builder: (context, _) {
            // Computed state
            // If sentence builder is showing, the question is NOT finished yet.
            final bool isGameAnswered =
                isAnsweredBloc ||
                (_pendingSelectedIndex.value != null &&
                    !_showSentenceBuilder.value);

            final bool isPassageLocked =
                isAnsweredBloc || _pendingSelectedIndex.value != null;

            final bool? isCorrect = _showSentenceBuilder.value
                ? true
                : isCorrectBloc;

            return ReadingBaseLayout(
              useScrolling: false,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isGameAnswered,
              isCorrect: isCorrect,
              showConfetti: showConfettiNotifier.value,
              disablePadding: true,
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<ReadingBloc>().add(const ReadingHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : RawScrollbar(
                      controller: _scrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SizedBox(height: 16.h),
                                  FindWordMeaningInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 24.h),
                                  FindWordMeaningQuestionHeader(
                                    text: quest.question ?? "",
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 32.h),
                                  FindWordMeaningInteractivePassage(
                                    passage: quest.passage ?? "",
                                    targetWord: quest.targetWord ?? "",
                                    primaryColor: theme.primaryColor,
                                    isDark: isDark,
                                    isAnswered: isPassageLocked,
                                    selectedIndex: _pendingSelectedIndex.value,
                                    isCorrectSelection: isCorrect,
                                    onWordSelected:
                                        (isCorrectTap, word, index) {
                                          _submitFinalAnswer(
                                            isCorrectTap,
                                            index,
                                            quest,
                                          );
                                        },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!_showSentenceBuilder.value)
                            SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: 40.h,
                                    bottom: 20.h,
                                  ),
                                  child: Icon(
                                    Icons.menu_book_rounded,
                                    size: 140.r,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.02)
                                        : theme.primaryColor.withValues(
                                            alpha: 0.05,
                                          ),
                                  ),
                                ),
                              ),
                            ),

                          if (_showSentenceBuilder.value)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(top: 24.h),
                                child: ContextSentenceBuilder(
                                  targetKeyword: quest.word ?? '',
                                  primaryColor: theme.primaryColor,
                                  onConfirmed: _onSentenceBuilderComplete,
                                  onSkipped: _onSentenceBuilderComplete,
                                  allowSkip: true,
                                  bonusCoins: 5,
                                  isPositioned: false,
                                  exampleSentence: quest.wordInContext,
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                  ? MediaQuery.of(context).viewInsets.bottom +
                                        40.h
                                  : 120.h,
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
