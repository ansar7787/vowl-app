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
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_instruction.dart';
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_pneumatic_port.dart';
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_fuel_cells.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/dynamic_anagram_wrapper.dart';

class ClozeTestScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ClozeTestScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.clozeTest,
  });

  @override
  State<ClozeTestScreen> createState() => _ClozeTestScreenState();
}

class _ClozeTestScreenState extends State<ClozeTestScreen>
    with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<String?> _dockedOption = ValueNotifier(null);
  final ValueNotifier<String?> _pendingDockedOption = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _dockedOption.dispose();
    _pendingDockedOption.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pendingDockedOption.addListener(() {
      if (_pendingDockedOption.value != null &&
          mounted &&
          _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });

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

  void _onDock(String option) {
    if (isAnsweredNotifier.value || _pendingDockedOption.value != null) return;
    hapticService.selection();
    _pendingDockedOption.value = option;
  }

  void _submitFinalAnswer(bool nailedTyping, ReadingQuest quest) {
    if (_pendingDockedOption.value == null) return;

    if (!nailedTyping) {
      _dockedOption.value = _pendingDockedOption.value;
      submitWrongAnswer(quest: quest, userAnswer: _pendingDockedOption.value);
      return;
    }

    final selected = _pendingDockedOption.value!;
    _dockedOption.value = _pendingDockedOption.value;
    _submitAnswer(selected, quest);
  }

  void _submitAnswer(String selected, ReadingQuest quest) {
    final correct = quest.correctAnswer ?? "";
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: selected);
    }
  }

  @override
  void onQuestionReset() {
    _dockedOption.value = null;
    _pendingDockedOption.value = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
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
            _dockedOption,
            _pendingDockedOption,
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
                                  ClozeTestInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction: quest.instruction,
                                  ),
                                  SizedBox(height: 32.h),

                                  ClozeTestPneumaticPort(
                                    text: quest.passage ?? "",
                                    correct: quest.correctAnswer ?? "",
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    dockedOption:
                                        _dockedOption.value ??
                                        _pendingDockedOption.value,
                                    wordCategory: quest.wordCategory,
                                    isAnswered: isAnsweredNotifier.value,
                                    onDock: (opt) => _onDock(opt),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(height: 40.h),
                                  ClozeTestFuelCells(
                                    options: quest.options ?? [],
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    dockedOption:
                                        _dockedOption.value ??
                                        _pendingDockedOption.value,
                                    onTap: (opt) => _onDock(opt),
                                  ),
                                  SizedBox(
                                    height:
                                        (_pendingDockedOption.value != null &&
                                            !isAnsweredNotifier.value)
                                        ? 380.h
                                        : 60.h,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_pendingDockedOption.value != null &&
                              !isAnsweredNotifier.value)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: DynamicAnagramWrapper(
                                  expectedText:
                                      _pendingDockedOption.value ?? "",
                                  isPositioned: false,
                                  primaryColor: theme.primaryColor,
                                  onConfirmed: () =>
                                      _submitFinalAnswer(true, quest),
                                  onFailed: () =>
                                      _submitFinalAnswer(false, quest),
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
