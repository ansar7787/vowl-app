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
import 'package:vowl/features/writing/summarize_story_writing/presentation/models/describe_frame_slot.dart';
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
    with WritingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<List<DescribeFrameSlot>> _slots = ValueNotifier([]);

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
    final newSlots = List<DescribeFrameSlot>.from(_slots.value);
    newSlots[slotIdx].sentence = sentence;
    _slots.value = newSlots;
  }

  void _onTapOption(String sentence, bool isAnswered) {
    if (isAnswered) return;

    final firstEmptyIdx = _slots.value.indexWhere((s) => s.sentence == null);
    if (firstEmptyIdx != -1) {
      hapticService.success();
      final newSlots = List<DescribeFrameSlot>.from(_slots.value);
      newSlots[firstEmptyIdx].sentence = sentence;
      _slots.value = newSlots;
    }
  }

  void _removeFrame(int slotIdx, bool isAnswered) {
    if (isAnswered) return;
    hapticService.selection();
    final newSlots = List<DescribeFrameSlot>.from(_slots.value);
    newSlots[slotIdx].sentence = null;
    _slots.value = newSlots;
  }

  void _submitAnswer(bool isAnswered) {
    if (isAnswered) return;
    _pendingSubmit.value = true;
    _scrollToBottom();
  }

  void _submitFinalAnswer(bool nailedTyping) {
    _pendingSubmit.value = false;

    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded) return;

    if (!nailedTyping) {
      hapticService.error();
      context.read<WritingBloc>().add(const SubmitAnswer(false));
      return;
    }

    final WritingQuest? quest = state.currentQuest as WritingQuest?;
    if (quest == null) return;

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

    context.read<WritingBloc>().add(SubmitAnswer(isAllCorrect));
  }

  void _onTimerExpired() {
    if (_pendingSubmit.value) return;
    hapticService.error();
    context.read<WritingBloc>().add(const SubmitAnswer(false));
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
    _slots.value = [];

    _pendingSubmit.value = false;
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
                (i) => DescribeFrameSlot(index: i),
              );
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

                                    if (quest.storyKeyEvents != null)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 24.h),
                                        padding: EdgeInsets.all(16.r),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          border: Border.all(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.checklist_rtl,
                                                  color: theme.primaryColor,
                                                  size: 16.sp,
                                                ),
                                                SizedBox(width: 8.w),
                                                Text(
                                                  "KEY EVENTS CHECKLIST",
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.w800,
                                                    color: theme.primaryColor,
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12.h),
                                            ...quest.storyKeyEvents!.map(
                                              (event) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 6.h,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      color: theme.primaryColor
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      size: 14.sp,
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Expanded(
                                                      child: Text(
                                                        event,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 12.sp,
                                                          color: isDark
                                                              ? Colors.white70
                                                              : Colors.black87,
                                                          height: 1.3,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

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
                                    if (!isAnswered)
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
                                  if (isSlotsFilled && !isAnswered)
                                    ScaleButton(
                                      onTap: () => _submitAnswer(isAnswered),
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
                                    TypeToConfirmOverlay(
                                      expectedText: _slots.value.isNotEmpty
                                          ? (_slots.value[0].sentence ?? "")
                                          : "",
                                      displayText:
                                          "Type the first sentence to finalize your summary",
                                      primaryColor: theme.primaryColor,
                                      onConfirmed: () =>
                                          _submitFinalAnswer(true),
                                      onSkipped: () =>
                                          _submitFinalAnswer(false),
                                      allowSkip: true,
                                      isPositioned: false,
                                    ),
                                  SizedBox(
                                    height: !isAnswered
                                        ? MediaQuery.viewInsetsOf(
                                                context,
                                              ).bottom +
                                              40.h
                                        : 160.h,
                                  ),
                                ],
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
                    );
            },
          ),
        );
      },
    );
  }
}
