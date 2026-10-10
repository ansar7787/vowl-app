import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
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
import 'package:vowl/core/utils/instruction_helper.dart';

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

class _EssayDraftingScreenState extends State<EssayDraftingScreen>
    with
        GameScreenMixin<EssayDraftingScreen>,
        WritingGameScreenMixin<EssayDraftingScreen> {
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
    _scrollController = ScrollController();
    initWritingGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<WritingBloc>().state;
        onWritingStateChanged(context, state);
      }
    });
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

  void _submitAnswer(bool isAnswered, WritingQuest quest) {
    if (isAnswered) return;

    final points = quest.requiredPoints ?? [];
    final options = quest.options ?? [];
    final correctOrderIndices = quest.correctOrder ?? [0, 1, 2, 3];

    if (points.isEmpty || options.isEmpty || correctOrderIndices.isEmpty) {
      return;
    }

    bool isCorrect = true;
    for (int i = 0; i < points.length; i++) {
      if (i >= correctOrderIndices.length) break;
      if (_blueprintSlots.value[points[i]] != options[correctOrderIndices[i]]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      hapticService.success();
      _pendingSubmit.value = true;
      _scrollToBottom();
    } else {
      hapticService.error();
      final userAns = points
          .map((p) => _blueprintSlots.value[p] ?? '')
          .join('; ');
      submitWrongAnswer(quest: quest, userAnswer: userAns);
    }
  }

  void _submitFinalAnswer(bool nailedTyping) {
    _pendingSubmit.value = false;

    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded) return;

    if (!nailedTyping) {
      hapticService.error();
      submitWrongAnswer(quest: state.currentQuest);
      return;
    }

    submitCorrectAnswer();
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
  void onWritingStateChanged(BuildContext context, WritingState state) {
    super.onWritingStateChanged(context, state);

    if (state is WritingLoaded) {
      final currentQuest = state.currentQuest as WritingQuest?;
      if (_lastQuest?.id != currentQuest?.id || _blueprintSlots.value.isEmpty) {
        _lastQuest = currentQuest;
        if (currentQuest != null) {
          final Map<String, String?> slots = {};
          for (final point in currentQuest.requiredPoints ?? []) {
            slots[point.toString()] = null;
          }
          _blueprintSlots.value = slots;
          
          final opts = List<String>.from(currentQuest.options ?? []);
          opts.shuffle();
          _shuffledOptions.value = opts;
          
          _pendingSubmit.value = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: writingListenWhen,
      listener: onWritingStateChanged,
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        final WritingQuest? quest = isLoaded
            ? state.currentQuest as WritingQuest?
            : null;

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
                                      instruction: InstructionHelper.getInstruction(activeQuest),
                                    ),
                                    SizedBox(height: 24.h),

                                    EssayDraftingTopicBanner(
                                      topic: activeQuest.essayTopic ?? "",
                                      thesisStatement: activeQuest.thesisStatement,
                                      color: theme.primaryColor,
                                      isDark: isDark,
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
                                  if (!isAnswered && !_pendingSubmit.value)
                                    ScaleButton(
                                      onTap: slotsFilled
                                          ? () => _submitAnswer(
                                              isAnswered,
                                              activeQuest,
                                            )
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
                                              : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
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
                                            "CONFIRM OUTLINE",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w700,
                                              color: slotsFilled
                                                  ? Colors.white
                                                  : (isDark ? Colors.white30 : Colors.black26),
                                              letterSpacing: 1.5,
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
                                          "Type the sentence to confirm",
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
                                        ? (_pendingSubmit.value
                                              ? MediaQuery.viewInsetsOf(
                                                      context,
                                                    ).bottom +
                                                    40.h
                                              : 60.h)
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
