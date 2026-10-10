import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';

import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/models/summarize_story_frame_slot.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_writing_instruction.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_manuscript.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_film_strip.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_frame_vault.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';

class SummarizeStoryWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SummarizeStoryWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.summarizeStoryWriting,
  });

  @override
  State<SummarizeStoryWritingScreen> createState() =>
      _SummarizeStoryWritingScreenState();
}

class _SummarizeStoryWritingScreenState
    extends State<SummarizeStoryWritingScreen>
    with
        GameScreenMixin<SummarizeStoryWritingScreen>,
        WritingGameScreenMixin<SummarizeStoryWritingScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<List<SummarizeStoryFrameSlot>> _slots = ValueNotifier([]);

  WritingQuest? _lastQuest;
  final ValueNotifier<bool> _pendingSubmit = ValueNotifier(false);

  late final ScrollController _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    _slots.dispose();
    _pendingSubmit.dispose();
    disposeWritingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initWritingGame();
  }

  void _onDropFrame(int slotIdx, String sentence, bool isAnswered) {
    if (isAnswered) return;
    hapticService.success();
    final newSlots = List<SummarizeStoryFrameSlot>.from(_slots.value);
    newSlots[slotIdx] = newSlots[slotIdx].copyWith(sentence: sentence);
    _slots.value = newSlots;
  }

  void _onTapOption(String sentence, bool isAnswered) {
    if (isAnswered) return;

    final firstEmptyIdx = _slots.value.indexWhere((s) => s.sentence == null);
    if (firstEmptyIdx != -1) {
      hapticService.success();
      final newSlots = List<SummarizeStoryFrameSlot>.from(_slots.value);
      newSlots[firstEmptyIdx] = newSlots[firstEmptyIdx].copyWith(
        sentence: sentence,
      );
      _slots.value = newSlots;
    }
  }

  void _removeFrame(int slotIdx, bool isAnswered) {
    if (isAnswered) return;
    hapticService.selection();
    final newSlots = List<SummarizeStoryFrameSlot>.from(_slots.value);
    newSlots[slotIdx] = newSlots[slotIdx].copyWith(clearSentence: true);
    _slots.value = newSlots;
  }

  void _submitAnswer(bool isAnswered, WritingQuest quest) {
    if (isAnswered) return;

    final options = quest.options ?? [];
    final correctIndices = quest.correctOrder ?? [0, 1, 2];

    bool isAllCorrect = true;
    for (int i = 0; i < _slots.value.length; i++) {
      final slotSentence = _slots.value[i].sentence;
      final targetIdx = correctIndices[i];
      final targetSentence = options[targetIdx];

      if (slotSentence != targetSentence) {
        isAllCorrect = false;
        break;
      }
    }

    if (isAllCorrect) {
      hapticService.success();
      _pendingSubmit.value = true;
      _scrollToBottom();
    } else {
      hapticService.error();
      final userAns = _slots.value.map((s) => s.sentence ?? '').join('; ');
      submitWrongAnswer(quest: quest, userAnswer: userAns);
    }
  }

  void _submitFinalAnswer(bool nailedTyping) {
    _pendingSubmit.value = false;

    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded) return;

    final WritingQuest? quest = state.currentQuest as WritingQuest?;
    if (quest == null) return;

    if (!nailedTyping) {
      hapticService.error();
      submitWrongAnswer(quest: quest);
      return;
    }

    submitCorrectAnswer();
  }

  void _onTimerExpired() {
    if (_pendingSubmit.value) return;
    hapticService.error();
    final state = context.read<WritingBloc>().state;
    final quest = (state is WritingLoaded) ? state.currentQuest : _lastQuest;
    if (quest != null) {
      submitWrongAnswer(quest: quest);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void onQuestionReset() {
    final newSlots = List<SummarizeStoryFrameSlot>.from(_slots.value);
    for (int i = 0; i < newSlots.length; i++) {
      newSlots[i] = newSlots[i].copyWith(clearSentence: true);
    }
    _slots.value = newSlots;

    _pendingSubmit.value = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
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
          final newQuest = state.currentQuest as WritingQuest?;
          if (_lastQuest?.id != newQuest?.id) {
            _lastQuest = newQuest;
            if (newQuest != null) {
              final correctCount = newQuest.correctOrder?.length ?? 3;
              _slots.value = List.generate(
                correctCount,
                (i) => SummarizeStoryFrameSlot(index: i),
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _pendingSubmit.value = false;
              });
            }
          }
        }

        final WritingQuest? quest = _lastQuest;

        final options = quest?.options ?? [];

        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: showConfettiNotifier.value,
          useScrolling: false,
          disablePadding: true,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<WritingBloc>().add(const WritingHintUsed()),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              showConfettiNotifier,
              _slots,
              _pendingSubmit,
            ]),
            builder: (context, _) {
              final isSlotsFilled =
                  _slots.value.isNotEmpty &&
                  _slots.value.every((s) => s.sentence != null);

              return quest == null
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
                              child: AbsorbPointer(
                                absorbing: _pendingSubmit.value && !isAnswered,
                                child: Column(
                                  children: [
                                    SizedBox(height: 16.h),
                                    SummarizeStoryWritingInstruction(
                                      instruction: context.tr(
                                        'games.summarizeStoryWriting_instruction',
                                        fallback:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      primaryColor: theme.primaryColor,
                                    ),
                                    SizedBox(height: 24.h),

                                    SummarizeStoryManuscript(
                                      story: quest.story ?? "",
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                    ),
                                    SizedBox(height: 24.h),

                                    SummarizeStoryFilmStrip(
                                      slots: _slots.value,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      onDropFrame: (idx, sentence) =>
                                          _onDropFrame(
                                            idx,
                                            sentence,
                                            isAnswered,
                                          ),
                                      onRemoveFrame: (idx) =>
                                          _removeFrame(idx, isAnswered),
                                    ),
                                    SizedBox(height: 24.h),

                                    SummarizeStoryFrameVault(
                                      options: options,
                                      slots: _slots.value,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      onTapOption: (text) =>
                                          _onTapOption(text, isAnswered),
                                    ),
                                    SizedBox(height: 32.h),
                                    if (!isAnswered && !_pendingSubmit.value)
                                      SpeedChallengeTimer(
                                        durationSeconds: 90,
                                        primaryColor: theme.primaryColor,
                                        onTimeUp: _onTimerExpired,
                                      ),
                                    SizedBox(height: 32.h),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isSlotsFilled &&
                                      !isAnswered &&
                                      !_pendingSubmit.value)
                                    ScaleButton(
                                      onTap: () =>
                                          _submitAnswer(isAnswered, quest),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 18.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            context.tr(
                                              'common.check_answer',
                                              fallback: 'CHECK ANSWER',
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_pendingSubmit.value && !isAnswered)
                                    Padding(
                                      padding: EdgeInsets.only(top: 48.h),
                                      child: TypeToConfirmOverlay(
                                        expectedText: _slots.value.isNotEmpty
                                            ? (_slots.value
                                                  .map((s) => s.sentence ?? "")
                                                  .join(" ")
                                                  .trim()
                                                  .replaceAll(
                                                    RegExp(r'\s+'),
                                                    ' ',
                                                  ))
                                            : "",
                                        displayText: _slots.value.isNotEmpty
                                            ? (_slots.value
                                                  .map((s) => s.sentence ?? "")
                                                  .join(" ")
                                                  .trim()
                                                  .replaceAll(
                                                    RegExp(r'\s+'),
                                                    ' ',
                                                  ))
                                            : "",
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitFinalAnswer(true),
                                        onSkipped: () =>
                                            _submitFinalAnswer(false),
                                        allowSkip: true,
                                        isPositioned: false,
                                        displayFontSize: 16.sp,
                                        displayFontWeight: FontWeight.w600,
                                        displayTextAlign: TextAlign.start,
                                      ),
                                    ),
                                  SizedBox(
                                    height:
                                        MediaQuery.viewInsetsOf(
                                              context,
                                            ).bottom >
                                            0
                                        ? MediaQuery.viewInsetsOf(
                                                context,
                                              ).bottom +
                                              40.h
                                        : (isAnswered
                                              ? 160.h
                                              : (_pendingSubmit.value
                                                    ? 40.h
                                                    : 80.h)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
            },
          ),
        );
      },
    );
  }
}
