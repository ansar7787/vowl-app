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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_instruction.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_topic_banner.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_hex_slot.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_data_stream.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class EssayDraftingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EssayDraftingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.essayDrafting,
  });

  @override
  State<EssayDraftingScreen> createState() => _EssayDraftingScreenState();
}

class _EssayDraftingScreenState extends State<EssayDraftingScreen> with WritingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  
  final ValueNotifier<Map<String, String?>> _blueprintSlots = ValueNotifier({});
  WritingQuest? _lastQuest;
  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);

    final ValueNotifier<bool> _pendingSubmit = ValueNotifier(false);

  late final ScrollController _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    _blueprintSlots.dispose();
    _shuffledOptions.dispose();
        _pendingSubmit.dispose();
    disposeWritingGame();
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

    _scrollController = ScrollController();
    initWritingGame();
  }

  void _onSlot(String slotKey, String data, bool isAnswered) {
    if (isAnswered) return;

    hapticService.success();
    final newSlots = Map<String, String?>.from(_blueprintSlots.value);
    newSlots.forEach((key, val) {
      if (val == data) {
        newSlots[key] = null;
      }
    });
    newSlots[slotKey] = data;
    _blueprintSlots.value = newSlots;
  }

  void _clearSlot(String slotKey, bool isAnswered) {
    if (isAnswered || _blueprintSlots.value[slotKey] == null) return;
    hapticService.selection();
    final newSlots = Map<String, String?>.from(_blueprintSlots.value);
    newSlots[slotKey] = null;
    _blueprintSlots.value = newSlots;
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

    final quest = state.currentQuest;
    final points = quest.requiredPoints ?? [];
    final options = quest.options ?? [];
    final correctOrderIndices = quest.correctOrder ?? [0, 1, 2, 3];

    if (points.length != 4 ||
        options.length != 4 ||
        correctOrderIndices.length != 4) {
      return;
    }

    bool isSlot0Correct =
        _blueprintSlots.value[points[0]] == options[correctOrderIndices[0]];
    bool isSlot1Correct =
        _blueprintSlots.value[points[1]] == options[correctOrderIndices[1]];
    bool isSlot2Correct =
        _blueprintSlots.value[points[2]] == options[correctOrderIndices[2]];
    bool isSlot3Correct =
        _blueprintSlots.value[points[3]] == options[correctOrderIndices[3]];

    final isCorrect =
        isSlot0Correct && isSlot1Correct && isSlot2Correct && isSlot3Correct;

    context.read<WritingBloc>().add(SubmitAnswer(isCorrect));
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

    _blueprintSlots.value = {};

    _shuffledOptions.value = [];

    _pendingSubmit.value = false;

  }

  @override

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: onWritingStateChanged,
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        final WritingQuest? quest = isLoaded
            ? state.currentQuest as WritingQuest?
            : null;

        if (quest != null) {
          _lastQuest = quest;
        }

        final activeQuest = quest ?? _lastQuest;

        final options = activeQuest?.options ?? [];

        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;
        final bool isFinalFailure = state.livesRemaining == 0;

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
          child: ListenableBuilder(
            listenable: Listenable.merge([
              showConfettiNotifier,
              _blueprintSlots,
              _shuffledOptions,
              _pendingSubmit,
            ]),
            builder: (context, _) {
              final slotsFilled =
                  _blueprintSlots.value.values.every((v) => v != null) &&
                  _blueprintSlots.value.isNotEmpty;

              return activeQuest == null
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
                                    EssayDraftingInstruction(
                                      primaryColor: theme.primaryColor,
                                      instruction: activeQuest.instruction,
                                    ),
                                    SizedBox(height: 24.h),

                                    EssayDraftingTopicBanner(
                                      topic: activeQuest.essayTopic ?? "",
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                    ),
                                    SizedBox(height: 16.h),
                                    if (activeQuest.thesisStatement != null)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 16.h),
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
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
                                                  Icons.center_focus_strong,
                                                  color: theme.primaryColor,
                                                  size: 14.sp,
                                                ),
                                                SizedBox(width: 8.w),
                                                Text(
                                                  "THESIS STATEMENT",
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.w800,
                                                    color: theme.primaryColor,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            Text(
                                              activeQuest.thesisStatement!,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    SizedBox(height: 8.h),

                                    ..._blueprintSlots.value.keys.map(
                                      (k) => EssayDraftingHexSlot(
                                        slotKey: k,
                                        slotValue: _blueprintSlots.value[k],
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        onSlot: (key, data) =>
                                            _onSlot(key, data, isAnswered),
                                        onClearSlot: (key) =>
                                            _clearSlot(key, isAnswered),
                                      ),
                                    ),
                                    SizedBox(height: 24.h),

                                    EssayDraftingDataStream(
                                      items: _shuffledOptions.value.isNotEmpty
                                          ? _shuffledOptions.value
                                          : options,
                                      slots: _blueprintSlots.value,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                    ),
                                    SizedBox(height: 16.h),
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
                                  if (!isAnswered)
                                    ScaleButton(
                                      onTap: slotsFilled
                                          ? () => _submitAnswer(isAnswered)
                                          : null,
                                      child: Container(
                                        width: double.infinity,
                                        height: 60.h,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          color: slotsFilled
                                              ? theme.primaryColor
                                              : Colors.grey,
                                          boxShadow: [
                                            if (slotsFilled)
                                              BoxShadow(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 15,
                                              ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            "TRANSMIT BLUEPRINT",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 16.sp,
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
                                      expectedText:
                                          _blueprintSlots.value.isNotEmpty &&
                                              _blueprintSlots
                                                      .value
                                                      .values
                                                      .first !=
                                                  null
                                          ? _blueprintSlots.value.values.first!
                                          : "",
                                      displayText:
                                          "Type the first point to finalize the outline",
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
