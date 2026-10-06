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
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_instruction.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_cargo_crate.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_label_rack.dart';

import 'package:vowl/core/services/error_journal_collector.dart';

class GuessTitleScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GuessTitleScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.guessTitle,
  });

  @override
  State<GuessTitleScreen> createState() => _GuessTitleScreenState();
}

class _GuessTitleScreenState extends State<GuessTitleScreen>
    with
        GameScreenMixin<GuessTitleScreen>,
        ReadingGameScreenMixin<GuessTitleScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<String?> _selectedTitle = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _selectedTitle.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initReadingGame();
  }

  void _submitFinalAnswer(
    bool isCorrect, [
    ReadingQuest? quest,
    String? selectedOption,
  ]) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = isCorrect;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      if (quest != null) {
        ErrorJournalCollector.record(
          userId: 'local',
          gameType: widget.gameType.name,
          question: quest.question ?? InstructionHelper.getInstruction(quest),
          userAnswer: selectedOption ?? 'Unknown',
          correctAnswer: quest.correctAnswer ?? '',
          level: widget.level,
        );
      }
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _selectedTitle.value = null;
  }

  @override
  Widget build(BuildContext context) {
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
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
                                  GuessTitleInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 24.h),
                                  ValueListenableBuilder<String?>(
                                    valueListenable: _selectedTitle,
                                    builder: (context, selectedTitle, _) {
                                      return Column(
                                        children: [
                                          GuessTitleCargoCrate(
                                            passage: quest.passage ?? "",
                                            correct: quest.correctAnswer ?? "",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            selectedTitle: selectedTitle,
                                            isAnswered:
                                                isAnsweredNotifier.value,
                                            isCorrect: isCorrectNotifier.value,
                                            onAccept: (title) {
                                              _selectedTitle.value = title;
                                              final isCorrect =
                                                  title.trim().toLowerCase() ==
                                                  (quest.correctAnswer ?? "")
                                                      .trim()
                                                      .toLowerCase();
                                              _submitFinalAnswer(
                                                isCorrect,
                                                quest,
                                                title,
                                              );
                                            },
                                          ),
                                          SizedBox(height: 32.h),
                                          if (!isAnsweredNotifier.value ||
                                              isCorrectNotifier.value == false)
                                            GuessTitleLabelRack(
                                              labels: quest.options ?? [],
                                              correct:
                                                  quest.correctAnswer ?? "",
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                              selectedTitle: selectedTitle,
                                              isAnswered:
                                                  isAnsweredNotifier.value,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                  if (isAnsweredNotifier.value) ...[
                                    SizedBox(height: 24.h),
                                    _buildExplanationCard(
                                      quest,
                                      theme.primaryColor,
                                      isDark,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: 60.h),
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

  Widget _buildExplanationCard(
    ReadingQuest quest,
    Color primaryColor,
    bool isDark,
  ) {
    if (quest.whyThisTitle == null && quest.explanation == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Why this title?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (quest.whyThisTitle != null) ...[
            Text(
              quest.whyThisTitle!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.5,
              ),
            ),
            SizedBox(height: 12.h),
          ],
          if (quest.explanation != null)
            Text(
              quest.explanation!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
