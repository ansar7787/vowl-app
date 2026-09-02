import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';

import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/models/describe_frame_slot.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_writing_instruction.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_manuscript.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_film_strip.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_frame_vault.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';

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
    extends State<SummarizeStoryWritingScreen> {
  final _hapticService = di.sl<HapticService>();

  final ValueNotifier<List<DescribeFrameSlot>> _slots = ValueNotifier([]);

  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  WritingQuest? _lastQuest;
  final ValueNotifier<bool> _pendingSubmit = ValueNotifier(false);

  late final ScrollController _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    _slots.dispose();
    _showConfetti.dispose();
    _pendingSubmit.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onDropFrame(int slotIdx, String sentence, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.success();
    final newSlots = List<DescribeFrameSlot>.from(_slots.value);
    newSlots[slotIdx].sentence = sentence;
    _slots.value = newSlots;
  }

  void _onTapOption(String sentence, bool isAnswered) {
    if (isAnswered) return;

    final firstEmptyIdx = _slots.value.indexWhere((s) => s.sentence == null);
    if (firstEmptyIdx != -1) {
      _hapticService.success();
      final newSlots = List<DescribeFrameSlot>.from(_slots.value);
      newSlots[firstEmptyIdx].sentence = sentence;
      _slots.value = newSlots;
    }
  }

  void _removeFrame(int slotIdx, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.selection();
    final newSlots = List<DescribeFrameSlot>.from(_slots.value);
    newSlots[slotIdx].sentence = null;
    _slots.value = newSlots;
  }

  void _submitAnswer(bool isAnswered) {
    if (isAnswered) return;
    _pendingSubmit.value = true;
  }

  void _submitFinalAnswer(bool nailedTyping) {
    _pendingSubmit.value = false;

    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded) return;

    if (!nailedTyping) {
      _hapticService.error();
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
    _hapticService.error();
    context.read<WritingBloc>().add(const SubmitAnswer(false));
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
      listener: (context, state) {
        if (state is WritingLoaded && !state.answerStatus.isAnswered) {
          _pendingSubmit.value = false;
          final newSlots = List<DescribeFrameSlot>.from(_slots.value);
          for (var slot in newSlots) {
            slot.sentence = null;
          }
          _slots.value = newSlots;
        }
        if (state is WritingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'DIGEST MASTER!',
            enableDoubleUp: true,
          );
        }

        if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () =>
                context.read<WritingBloc>().add(const RestoreLife()),
          );
        }
      },
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
          showConfetti: _showConfetti.value,
          useScrolling: false,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<WritingBloc>().add(const WritingHintUsed()),
          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _slots, _pendingSubmit]),
            builder: (context, _) {
              final isSlotsFilled = _slots.value.isNotEmpty && _slots.value.every((s) => s.sentence != null);

              return quest == null
                  ? const SizedBox()
                  : Stack(
                  children: [
                    LayoutBuilder(
                  builder: (context, constraints) {
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
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                SizedBox(height: 16.h),
                                SummarizeStoryWritingInstruction(
                                  instruction: context.tr(
                                    'games.summarizeStoryWriting_instruction',
                                    fallback: quest.instruction,
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
                                      color: theme.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.checklist_rtl, color: theme.primaryColor, size: 16.sp),
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
                                        ...quest.storyKeyEvents!.map((event) => Padding(
                                          padding: EdgeInsets.only(bottom: 6.h),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.check_circle_outline, color: theme.primaryColor.withValues(alpha: 0.7), size: 14.sp),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Text(
                                                  event,
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 12.sp,
                                                    color: isDark ? Colors.white70 : Colors.black87,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                      ],
                                    ),
                                  ),

                                SummarizeStoryFilmStrip(
                                  slots: _slots.value,
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                  onDropFrame: (idx, sentence) =>
                                      _onDropFrame(idx, sentence, isAnswered),
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
                                      padding: EdgeInsets.symmetric(vertical: 18.h),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        borderRadius: BorderRadius.circular(20.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor.withValues(
                                              alpha: 0.4,
                                            ),
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
                                SizedBox(height: !isAnswered ? 380.h : 160.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    );
                  },
                ),
                    if (_pendingSubmit.value && !isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: _slots.value.isNotEmpty
                            ? (_slots.value[0].sentence ?? "")
                            : "",
                        displayText:
                            "Type the first sentence to finalize your summary",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        allowSkip: true,
                      ),
                  ],
                );
            },
          ),
        );
      },
    );
  }
}
