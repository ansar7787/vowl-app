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
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_instruction.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_passage.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_options.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_logic_chain.dart';

class ReadingConclusionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingConclusionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingConclusion,
  });

  @override
  State<ReadingConclusionScreen> createState() =>
      _ReadingConclusionScreenState();
}

class _ReadingConclusionScreenState extends State<ReadingConclusionScreen>
    with
        GameScreenMixin<ReadingConclusionScreen>,
        ReadingGameScreenMixin<ReadingConclusionScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();
  int? _selectedIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initReadingGame();
  }

  @override
  void onQuestionReset() {
    super.onQuestionReset();
    setState(() {
      _selectedIndex = null;
    });
  }

  void _onOptionTap(int index, String optionText, ReadingQuest quest) {
    if (isAnsweredNotifier.value) return;

    hapticService.selection();

    setState(() {
      _selectedIndex = index;
    });

    final correctAnswer = quest.correctAnswer ?? '';
    final isCorrect =
        optionText.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: optionText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: onReadingStateChanged,
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              useScrolling: false,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
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
                                  ReadingConclusionInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 32.h),
                                  ReadingConclusionPassage(
                                    passage: quest.passage ?? "",
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 32.h),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: ReadingConclusionOptions(
                                options: quest.options ?? [],
                                correct: quest.correctAnswer ?? '',
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                selectedIndex: _selectedIndex,
                                isAnswered: isAnsweredNotifier.value,
                                onOptionTap: (index, optionText) =>
                                    _onOptionTap(index, optionText, quest),
                              ),
                            ),
                          ),
                          if (isAnsweredNotifier.value &&
                              quest.logicChain != null &&
                              quest.logicChain!.isNotEmpty)
                            SliverPadding(
                              padding: EdgeInsets.only(
                                left: 24.w,
                                right: 24.w,
                                top: 8.h,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: ReadingConclusionLogicChain(
                                  logicChain: quest.logicChain!,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 120.h,
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
