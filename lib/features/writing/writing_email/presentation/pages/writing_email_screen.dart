import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_instruction.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_prompt_card.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_hex_slot.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_data_stream.dart';

class WritingEmailScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WritingEmailScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.writingEmail,
  });

  @override
  State<WritingEmailScreen> createState() => _WritingEmailScreenState();
}

class _WritingEmailScreenState extends State<WritingEmailScreen>
    with
        GameScreenMixin<WritingEmailScreen>,
        WritingGameScreenMixin<WritingEmailScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<Map<String, String?>> _slots = ValueNotifier({});
  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
  WritingQuest? _lastQuest;
  List<String> _currentSlotKeys = [];

  late final ScrollController _scrollController;

  List<String> _getSlotKeys(int count) {
    if (count == 4) {
      return ['SUBJECT', 'GREETING', 'BODY', 'SIGN-OFF'];
    }
    return List.generate(count, (i) => 'PART ${i + 1}');
  }

  @override
  void onWritingStateChanged(BuildContext context, WritingState state) {
    super.onWritingStateChanged(context, state);
    if (state is WritingLoaded && state.currentQuest != _lastQuest) {
      _lastQuest = state.currentQuest;
      final opts = List<String>.from(state.currentQuest.options ?? []);

      _currentSlotKeys = _getSlotKeys(opts.length);
      final newSlots = <String, String?>{};
      for (final key in _currentSlotKeys) {
        newSlots[key] = null;
      }
      _slots.value = newSlots;

      opts.shuffle();
      _shuffledOptions.value = opts;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _slots.dispose();
    _shuffledOptions.dispose();
    disposeWritingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initWritingGame();
  }

  void _onSlot(String slotKey, String data, bool isAnswered) {
    if (isAnswered) return;

    hapticService.success();
    final newSlots = Map<String, String?>.from(_slots.value);
    newSlots.forEach((key, val) {
      if (val == data) {
        newSlots[key] = null;
      }
    });
    newSlots[slotKey] = data;
    _slots.value = newSlots;
  }

  void _onTapOption(String data, bool isAnswered) {
    if (isAnswered) return;

    String? targetSlot;
    for (final key in _currentSlotKeys) {
      if (_slots.value[key] == null) {
        targetSlot = key;
        break;
      }
    }

    if (targetSlot != null) {
      hapticService.success();
      final newSlots = Map<String, String?>.from(_slots.value);
      newSlots.forEach((key, val) {
        if (val == data) {
          newSlots[key] = null;
        }
      });
      newSlots[targetSlot] = data;
      _slots.value = newSlots;
    } else {
      hapticService.error();
    }
  }

  void _clearSlot(String slotKey, bool isAnswered) {
    if (isAnswered || _slots.value[slotKey] == null) return;
    hapticService.selection();
    final newSlots = Map<String, String?>.from(_slots.value);
    newSlots[slotKey] = null;
    _slots.value = newSlots;
  }

  void _submitAnswer(bool isAnswered) {
    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded || isAnswered) return;

    final WritingQuest? quest = state.currentQuest as WritingQuest?;
    if (quest == null) return;

    final options = quest.options ?? [];
    // fallback to [0, 1, 2, 3...] if not provided
    final correctOrderIndices =
        quest.correctOrder ?? List.generate(_currentSlotKeys.length, (i) => i);

    bool isCorrect = true;
    for (int i = 0; i < _currentSlotKeys.length; i++) {
      final key = _currentSlotKeys[i];
      final expectedIndex = (i < correctOrderIndices.length)
          ? correctOrderIndices[i]
          : i;
      final expectedValue = (expectedIndex < options.length)
          ? options[expectedIndex]
          : null;
      if (_slots.value[key] != expectedValue) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      hapticService.success();
      submitCorrectAnswer();
    } else {
      hapticService.error();
      final userAns = _currentSlotKeys
          .map((key) => "$key: ${_slots.value[key] ?? ''}")
          .join(", ");
      submitWrongAnswer(quest: quest, userAnswer: userAns);
    }
  }

  @override
  void onQuestionReset() {
    final newSlots = <String, String?>{};
    for (final key in _currentSlotKeys) {
      newSlots[key] = null;
    }
    _slots.value = newSlots;

    _shuffledOptions.value = [];
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
        final WritingQuest? quest = isLoaded ? state.currentQuest : _lastQuest;

        final options = quest?.options ?? [];

        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;

        final lives = state.livesRemaining;
        final bool isFinalFailure = isLoaded
            ? state.isFinalFailure
            : (lives == 0);

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: showConfettiNotifier.value,
          useScrolling: false,
          disablePadding: true,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: (state is WritingLoading || _lastQuest == null)
              ? GameShimmerLoading(primaryColor: theme.primaryColor)
              : quest == null
              ? GameShimmerLoading(primaryColor: theme.primaryColor)
              : ListenableBuilder(
                  listenable: Listenable.merge([
                    showConfettiNotifier,
                    _slots,
                    _shuffledOptions,
                  ]),
                  builder: (context, _) {
                    final slotsFilled = _slots.value.values.every(
                      (v) => v != null,
                    );

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
                                  WritingEmailInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                    formalityLevel: quest.formalityLevel
                                        ?.toUpperCase(),
                                  ),
                                  SizedBox(height: 16.h),
                                  WritingEmailPromptCard(
                                    text: quest.prompt ?? "",
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 24.h),

                                  ..._slots.value.keys.map(
                                    (k) => WritingEmailHexSlot(
                                      slotKey: k,
                                      slotValue: _slots.value[k],
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      onSlot: (key, data) =>
                                          _onSlot(key, data, isAnswered),
                                      onClearSlot: (key) =>
                                          _clearSlot(key, isAnswered),
                                    ),
                                  ),
                                  if (!slotsFilled && !isAnswered) ...[
                                    SizedBox(height: 24.h),
                                    WritingEmailDataStream(
                                      items: _shuffledOptions.value.isNotEmpty
                                          ? _shuffledOptions.value
                                          : options,
                                      slots: _slots.value,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      onTapItem: (data) =>
                                          _onTapOption(data, isAnswered),
                                    ),
                                    SizedBox(height: 32.h),
                                  ] else ...[
                                    SizedBox(height: 48.h),
                                  ],
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
                                            "Send",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
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
