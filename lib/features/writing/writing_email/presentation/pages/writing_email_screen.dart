import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_instruction.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_prompt_card.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_hex_slot.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_data_stream.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_keyboard_input.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

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
    with WritingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<Map<String, String?>> _slots = ValueNotifier({
    'SUBJECT': null,
    'SALUTATION': null,
    'BODY': null,
    'SIGN-OFF': null,
  });

  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
  final ValueNotifier<bool> _showSpeakToConfirm = ValueNotifier(false);
  WritingQuest? _lastQuest;

  late final ScrollController _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    _slots.dispose();
    _shuffledOptions.dispose();
    _showSpeakToConfirm.dispose();
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
    for (final key in ['SUBJECT', 'SALUTATION', 'BODY', 'SIGN-OFF']) {
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
    final correctOrderIndices = quest.correctOrder ?? [0, 1, 2, 3];

    bool isSubjectCorrect =
        _slots.value['SUBJECT'] == options[correctOrderIndices[0]];
    bool isSalutationCorrect =
        _slots.value['SALUTATION'] == options[correctOrderIndices[1]];
    bool isBodyCorrect =
        _slots.value['BODY'] == options[correctOrderIndices[2]];
    bool isSignOffCorrect =
        _slots.value['SIGN-OFF'] == options[correctOrderIndices[3]];

    final isCorrect =
        isSubjectCorrect &&
        isSalutationCorrect &&
        isBodyCorrect &&
        isSignOffCorrect;

    if (isCorrect) {
      hapticService.success();
      _showSpeakToConfirm.value = true;
    } else {
      hapticService.error();
      context.read<WritingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _onSpeakConfirmed() {
    _showSpeakToConfirm.value = false;
    context.read<WritingBloc>().add(const SubmitAnswer(true));
  }

  @override
  void onQuestionReset() {
    _slots.value = {
      'SUBJECT': null,
      'SALUTATION': null,
      'BODY': null,
      'SIGN-OFF': null,
    };

    _shuffledOptions.value = [];

    _showSpeakToConfirm.value = false;
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
        if (isLoaded && state.currentQuest != _lastQuest) {
          _lastQuest = state.currentQuest;
        }
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
                    _showSpeakToConfirm,
                  ]),
                  builder: (context, _) {
                    final slotsFilled = _slots.value.values.every(
                      (v) => v != null,
                    );

                    return Stack(
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
                                      WritingEmailInstruction(
                                        primaryColor: theme.primaryColor,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 16.h),
                                      if (quest.formalityLevel != null)
                                        Container(
                                          margin: EdgeInsets.only(bottom: 16.h),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 6.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            border: Border.all(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.mail_outline,
                                                color: theme.primaryColor,
                                                size: 14.sp,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                quest.formalityLevel!
                                                    .toUpperCase(),
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
                                        ),

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
                                        if (widget.level >= 6) ...[
                                          GestureDetector(
                                            onTap: () {
                                              CustomSnackBar.show(
                                                context: context,
                                                message:
                                                    "Hard Mode! Tapping is disabled. Please type your answer below.",
                                                type: CustomSnackBarType.info,
                                              );
                                            },
                                            child: AbsorbPointer(
                                              child: Opacity(
                                                opacity: 0.8,
                                                child: WritingEmailDataStream(
                                                  items:
                                                      options, // Show full list for reference
                                                  slots: _slots.value,
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  onTapItem: (_) {}, // Disabled
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          WritingEmailKeyboardInput(
                                            validOptions: options
                                                .where(
                                                  (opt) => !_slots.value.values
                                                      .contains(opt),
                                                )
                                                .toList(),
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            onValidInput: (data) =>
                                                _onTapOption(data, isAnswered),
                                          ),
                                        ] else
                                          WritingEmailDataStream(
                                            items:
                                                _shuffledOptions
                                                    .value
                                                    .isNotEmpty
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!_showSpeakToConfirm.value &&
                                          !isAnswered)
                                        ScaleButton(
                                          onTap: slotsFilled
                                              ? () => _submitAnswer(isAnswered)
                                              : null,
                                          child: Container(
                                            width: double.infinity,
                                            height: 60.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
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
                                                "SEND EMAIL",
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
                        ),
                        if (_showSpeakToConfirm.value && !isAnswered)
                          SpeakToConfirmOverlay(
                            expectedText:
                                "${_slots.value['SUBJECT'] ?? ''} ${_slots.value['SALUTATION'] ?? ''} ${_slots.value['BODY'] ?? ''} ${_slots.value['SIGN-OFF'] ?? ''}"
                                    .trim(),
                            primaryColor: theme.primaryColor,
                            onConfirmed: _onSpeakConfirmed,
                            onSkipped: () {
                              _showSpeakToConfirm.value = false;
                              context.read<WritingBloc>().add(
                                const SubmitAnswer(false),
                              );
                            },
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
