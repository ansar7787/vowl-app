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
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_result.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_options.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
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
    with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<bool> _showTypeToConfirm = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _showTypeToConfirm.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    initReadingGame();
  }

  void _submitFinalAnswer(
    bool isCorrect, [
    ReadingQuest? quest,
    String? selectedOption,
  ]) {
    if (isAnsweredNotifier.value || _showTypeToConfirm.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = isCorrect;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      _showTypeToConfirm.value = true;
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

  void _onTypeConfirmed() {
    _showTypeToConfirm.value = false;
    context.read<ReadingBloc>().add(const SubmitAnswer(true));
  }

  @override
  void onQuestionReset() {
    _showTypeToConfirm.value = false;
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
            _showTypeToConfirm,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
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
                  : Stack(
                      children: [
                        RawScrollbar(
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
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(24.r),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.02,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          border: Border.all(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: _buildPassageContent(
                                          quest,
                                          theme.primaryColor,
                                          isDark,
                                        ),
                                      ),
                                      if (!isAnsweredNotifier.value ||
                                          isCorrectNotifier.value == null) ...[
                                        SizedBox(height: 24.h),
                                        GuessTitleOptions(
                                          options: quest.options ?? [],
                                          correctAnswer:
                                              quest.correctAnswer ?? "",
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          isAnswered: isAnsweredNotifier.value,
                                          onOptionSelected:
                                              (isCorrect, selectedOption) {
                                                _submitFinalAnswer(
                                                  isCorrect,
                                                  quest,
                                                  selectedOption,
                                                );
                                              },
                                        ),
                                      ],
                                      if (isAnsweredNotifier.value) ...[
                                        SizedBox(height: 30.h),
                                        GuessTitleResult(
                                          quest: quest,
                                          isCorrect:
                                              isCorrectNotifier.value == true,
                                          isDark: isDark,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      (_showTypeToConfirm.value &&
                                          isAnsweredNotifier.value)
                                      ? 380.h
                                      : 60.h,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showTypeToConfirm.value &&
                            isAnsweredNotifier.value)
                          TypeToConfirmOverlay(
                            expectedText: quest.correctAnswer ?? '',
                            primaryColor: theme.primaryColor,
                            onConfirmed: _onTypeConfirmed,
                            onSkipped: _onTypeConfirmed,
                            allowSkip: true,
                            isPositioned: true,
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildPassageContent(
    ReadingQuest quest,
    Color primaryColor,
    bool isDark,
  ) {
    final passage = quest.passage ?? "";
    final evidence = quest.evidenceLine ?? "";

    if (!isAnsweredNotifier.value ||
        evidence.isEmpty ||
        !passage.contains(evidence)) {
      return Text(
        passage,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );
    }

    final parts = passage.split(evidence);
    if (parts.length != 2) {
      return Text(
        passage,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: evidence,
            style: TextStyle(
              backgroundColor: primaryColor.withValues(alpha: 0.2),
              color: primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: parts[1]),
        ],
      ),
    );
  }
}
