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
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_instruction.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_passage.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_statement.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_coin_zone.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';
import 'package:vowl/core/services/error_journal_collector.dart';

class TrueFalseReadingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TrueFalseReadingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.trueFalseReading,
  });

  @override
  State<TrueFalseReadingScreen> createState() => _TrueFalseReadingScreenState();
}

class _TrueFalseReadingScreenState extends State<TrueFalseReadingScreen>
    with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<bool?> _pendingAnswer = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _pendingAnswer.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pendingAnswer.addListener(() {
      if (_pendingAnswer.value != null &&
          !isAnsweredNotifier.value &&
          mounted &&
          _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted &&
              _scrollController.hasClients &&
              !isAnsweredNotifier.value) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
    initReadingGame();
  }

  void _onAnswerSelected(bool isTrue) {
    if (isAnsweredNotifier.value || _pendingAnswer.value != null) return;

    final quest =
        (context.read<ReadingBloc>().state as ReadingLoaded).currentQuest;
    final String correct = quest.correctAnswer ?? "";
    final bool isCorrect =
        (isTrue ? "true" : "false") == correct.trim().toLowerCase();

    if (!isCorrect) {
      _pendingAnswer.value = isTrue;
      _submitFinalAnswer(false, quest, true);
    } else {
      _pendingAnswer.value = isTrue;
    }
  }

  void _submitFinalAnswer(
    bool nailedEvidence,
    ReadingQuest quest, [
    bool failedCoin = false,
  ]) {
    if (_pendingAnswer.value == null) return;

    if (!nailedEvidence || failedCoin) {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      ErrorJournalCollector.record(
        userId: 'local',
        gameType: widget.gameType.name,
        question: quest.question ?? InstructionHelper.getInstruction(quest),
        userAnswer: failedCoin
            ? (_pendingAnswer.value! ? "True" : "False")
            : 'Failed to find evidence',
        correctAnswer: failedCoin
            ? (quest.correctAnswer ?? '')
            : (quest.evidenceLine ?? ''),
        level: widget.level,
      );
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      return;
    }

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;

    hapticService.success();
    soundService.playCorrect();
    // Award bonus coins for finding evidence
    context.read<ReadingBloc>().add(const ReadingSpeakConfirmed(5));
    context.read<ReadingBloc>().add(const SubmitAnswer(true));
  }

  @override
  void onQuestionReset() {
    _pendingAnswer.value = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
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
            _pendingAnswer,
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
                                  TrueFalseReadingInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 24.h),
                                  TrueFalseReadingPassage(
                                    passage: quest.passage ?? "",
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 32.h),
                                  TrueFalseReadingStatement(
                                    statement: quest.question ?? "",
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(height: 40.h),
                                TrueFalseReadingCoinZone(
                                  key: ValueKey(quest.id),
                                  onAnswerSelected: _onAnswerSelected,
                                  isDisabled:
                                      isAnsweredNotifier.value ||
                                      _pendingAnswer.value != null,
                                  pendingAnswer: _pendingAnswer.value,
                                  isDark: isDark,
                                ),

                                SizedBox(
                                  height:
                                      (_pendingAnswer.value != null &&
                                          !isAnsweredNotifier.value)
                                      ? 380.h
                                      : 60.h,
                                ),
                              ],
                            ),
                          ),

                          if (_pendingAnswer.value != null &&
                              !isAnsweredNotifier.value)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: EvidenceHighlightWrapper(
                                  passage: quest.passage ?? "",
                                  evidenceWords:
                                      (quest.evidenceLine ?? quest.passage ?? "")
                                          .split(RegExp(r'\s+')),
                                  primaryColor: theme.primaryColor,
                                  onCorrectHighlight: () =>
                                      _submitFinalAnswer(true, quest),
                                  instruction:
                                      'Tap the words that prove your answer',
                                  isPositioned: false,
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
