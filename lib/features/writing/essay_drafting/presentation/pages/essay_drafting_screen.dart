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

/// Interactive writing game screen guiding users through structural drafting of argumentative essays.
class EssayDraftingScreen extends StatefulWidget {
  /// The difficulty or curriculum level of the writing quest.
  final int level;

  /// The specific writing game subtype represented by this screen.
  final GameSubtype gameType;

  /// Creates an [EssayDraftingScreen] instance.
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

  void _onOptionTapped(String item, bool isAnswered) {
    if (isAnswered) return;
    final currentSlots = _blueprintSlots.value;
    for (final entry in currentSlots.entries) {
      if (entry.value == null) {
        _onSlot(entry.key, item, isAnswered);
        return;
      }
    }
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

  void _handleAutoScroll(DragUpdateDetails details) {
    if (!_scrollController.hasClients) return;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double pointerY = details.globalPosition.dy;
    final double scrollThreshold = 150.0; // Margin from top/bottom
    final double scrollSpeed = 10.0;

    double newOffset = _scrollController.offset;

    if (pointerY < scrollThreshold) {
      // Scroll up
      newOffset -= scrollSpeed;
    } else if (pointerY > screenHeight - scrollThreshold) {
      // Scroll down
      newOffset += scrollSpeed;
    }

    if (newOffset != _scrollController.offset) {
      newOffset = newOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(newOffset);
    }
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
          onHint: () {},
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
                        key: const Key('essay_drafting_scroll_view'),
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  AbsorbPointer(
                                    absorbing:
                                        _pendingSubmit.value && !isAnswered,
                                    child: Column(
                                      children: [
                                        SizedBox(height: 16.h),
                                        EssayDraftingInstruction(
                                          primaryColor: theme.primaryColor,
                                          instruction:
                                              InstructionHelper.getInstruction(
                                                activeQuest,
                                              ),
                                        ),
                                        SizedBox(height: 24.h),

                                        EssayDraftingTopicBanner(
                                          topic: activeQuest.essayTopic ?? "",
                                          thesisStatement:
                                              activeQuest.thesisStatement,
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
                                          items:
                                              _shuffledOptions.value.isNotEmpty
                                              ? _shuffledOptions.value
                                              : options,
                                          slots: _blueprintSlots.value,
                                          color: theme.primaryColor,
                                          isDark: isDark,
                                          onDragUpdate: _handleAutoScroll,
                                          onItemTap: (item) =>
                                              _onOptionTapped(item, isAnswered),
                                        ),
                                        SizedBox(height: 16.h),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                  if (!isAnswered && !_pendingSubmit.value)
                                    ScaleButton(
                                      key: const Key(
                                        'essay_drafting_confirm_button',
                                      ),
                                      onTap: slotsFilled
                                          ? () => _submitAnswer(
                                              isAnswered,
                                              activeQuest,
                                            )
                                          : null,
                                      child: Container(
                                        width: double.infinity,
                                        constraints: BoxConstraints(
                                          minHeight: 56.h,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          color: slotsFilled
                                              ? theme.primaryColor
                                              : (isDark
                                                    ? Colors.white12
                                                    : Colors.black.withValues(
                                                        alpha: 0.05,
                                                      )),
                                          boxShadow: [
                                            if (slotsFilled)
                                              BoxShadow(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 15,
                                                offset: const Offset(0, 4),
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
                                                  : (isDark
                                                        ? Colors.white30
                                                        : Colors.black26),
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_pendingSubmit.value && !isAnswered)
                                    TypeToConfirmOverlay(
                                      expectedText: _blueprintSlots.value.values
                                          .where((v) => v != null)
                                          .join(' '),
                                      primaryColor: theme.primaryColor,
                                      title: "Confirm Draft",
                                      subtitle:
                                          "Type the completed paragraph to confirm",
                                      hintText: "Type paragraph here...",
                                      onConfirmed: () =>
                                          _submitFinalAnswer(true),
                                      onSkipped: () =>
                                          _submitFinalAnswer(false),
                                      allowSkip: true,
                                      isPositioned: false,
                                      displayFontSize: 15.sp,
                                      displayFontWeight: FontWeight.w500,
                                      displayTextAlign: TextAlign.left,
                                    ),
                                  SizedBox(
                                    height: isAnswered
                                        ? 160.h
                                        : (_pendingSubmit.value
                                              ? MediaQuery.viewInsetsOf(
                                                      context,
                                                    ).bottom +
                                                    40.h
                                              : 120.h),
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
