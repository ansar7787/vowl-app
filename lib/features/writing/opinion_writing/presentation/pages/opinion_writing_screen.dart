import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/widgets/opinion_writing_option_card.dart';

class OpinionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const OpinionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.opinionWriting,
  });

  @override
  State<OpinionWritingScreen> createState() => _OpinionWritingScreenState();
}

class _OpinionWritingScreenState extends State<OpinionWritingScreen>
    with
        GameScreenMixin<OpinionWritingScreen>,
        WritingGameScreenMixin<OpinionWritingScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  WritingQuest? _lastQuest;
  bool _hasShuffled = false;
  List<String> _currentShuffledOptions = [];
  final ValueNotifier<Set<String>> _selectedOptions = ValueNotifier({});

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initWritingGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedOptions.dispose();
    disposeWritingGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    _hasShuffled = false;
    _currentShuffledOptions = [];
    _selectedOptions.value = {};
  }

  void _toggleSelection(String option, WritingQuest quest, bool isAnswered) {
    if (isAnswered) return;

    hapticService.selection();
    final requiredCount = quest.correctOrder?.length ?? 1;
    final currentSelection = Set<String>.from(_selectedOptions.value);

    if (currentSelection.contains(option)) {
      currentSelection.remove(option);
    } else {
      if (currentSelection.length < requiredCount) {
        currentSelection.add(option);
      } else if (requiredCount == 1) {
        currentSelection.clear();
        currentSelection.add(option);
      } else {
        // Option to swap the oldest one, but for now just clear and add for UX
        if (requiredCount > 1 && currentSelection.isNotEmpty) {
          currentSelection.remove(currentSelection.first);
          currentSelection.add(option);
        }
      }
    }

    _selectedOptions.value = currentSelection;
  }

  void _submitAnswer(WritingQuest quest) {
    final requiredCount = quest.correctOrder?.length ?? 1;
    if (_selectedOptions.value.length < requiredCount) return;

    final correctOptions =
        quest.correctOrder?.map((idx) => quest.options![idx]).toSet() ?? {};

    final isCorrect =
        _selectedOptions.value.length == correctOptions.length &&
        _selectedOptions.value.every((opt) => correctOptions.contains(opt));

    if (isCorrect) {
      hapticService.success();
      submitCorrectAnswer();
    } else {
      hapticService.error();
      final userAns = 'Selected: ${_selectedOptions.value.join(" | ")}';
      submitWrongAnswer(quest: quest, userAnswer: userAns);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingGameOver && prev is! WritingGameOver) ||
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: onWritingStateChanged,
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        if (isLoaded) {
          _lastQuest = state.currentQuest;
          if (!_hasShuffled && state.currentQuest.options != null) {
            _hasShuffled = true;
            _currentShuffledOptions = List<String>.from(
              state.currentQuest.options!,
            );
            _currentShuffledOptions.shuffle();
          }
        }
        final WritingQuest? quest = isLoaded ? state.currentQuest : _lastQuest;

        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;
        final bool isFinalFailure = isLoaded
            ? state.isFinalFailure
            : (state is WritingGameOver);

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: showConfettiNotifier.value,
          useScrolling: false,
          disablePadding: true,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<WritingBloc>().add(const WritingHintUsed()),
          child: quest == null || quest.options == null
              ? GameShimmerLoading(primaryColor: theme.primaryColor)
              : Builder(
                  builder: (context) {
                    final options = _currentShuffledOptions.isNotEmpty
                        ? _currentShuffledOptions
                        : (quest.options ?? <String>[]);

                    return ValueListenableBuilder<Set<String>>(
                      valueListenable: _selectedOptions,
                      builder: (context, selectedOptions, _) {
                        final requiredCount = quest.correctOrder?.length ?? 1;
                        final correctOptions =
                            quest.correctOrder
                                ?.map((idx) => quest.options![idx])
                                .toSet() ??
                            {};
                        final canSubmit =
                            selectedOptions.length == requiredCount;

                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 16.h,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    if (quest.prompt != null ||
                                        quest.structureGuide != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(20.w),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white12
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (quest.structureGuide !=
                                                null) ...[
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  quest.structureGuide!
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.5,
                                                    color: theme.primaryColor,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 12.h),
                                            ],
                                            if (quest.prompt != null)
                                              Text(
                                                quest.prompt!,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w400,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF475569),
                                                  height: 1.5,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                    ],
                                    if (quest.instruction.isNotEmpty) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 12.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          border: Border.all(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 2.h,
                                              ),
                                              child: Icon(
                                                Icons.flag_rounded,
                                                color: theme.primaryColor,
                                                size: 20.w,
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Text(
                                                quest.instruction,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF1E293B),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 24.h),
                                    ],
                                    ...options.map((option) {
                                      final isSelected = selectedOptions
                                          .contains(option);
                                      final isCorrectOption = correctOptions
                                          .contains(option);

                                      return OpinionWritingOptionCard(
                                        text: option,
                                        isSelected: isSelected,
                                        isAnswered: isAnswered,
                                        isCorrectOption: isCorrectOption,
                                        isMultiSelect: requiredCount > 1,
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        onTap: () => _toggleSelection(
                                          option,
                                          quest,
                                          isAnswered,
                                        ),
                                      );
                                    }),
                                    SizedBox(height: 24.h),
                                  ]),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Column(
                                    children: [
                                      if (!isAnswered)
                                        ScaleButton(
                                          onTap: canSubmit
                                              ? () => _submitAnswer(quest)
                                              : null,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            width: double.infinity,
                                            height: 60.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              color: canSubmit
                                                  ? theme.primaryColor
                                                  : Colors.grey.withValues(
                                                      alpha: 0.5,
                                                    ),
                                              boxShadow: canSubmit
                                                  ? [
                                                      BoxShadow(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        blurRadius: 15,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Center(
                                              child: Text(
                                                "SUBMIT",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(height: 120.h),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
