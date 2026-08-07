import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_instruction.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_prompt_card.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_hex_slot.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_data_stream.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_keyboard_input.dart';

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

class _WritingEmailScreenState extends State<WritingEmailScreen> {
  final _hapticService = di.sl<HapticService>();

  final Map<String, String?> _slots = {
    'SUBJECT': null,
    'SALUTATION': null,
    'BODY': null,
    'SIGN-OFF': null,
  };

  List<String> _shuffledOptions = [];
  bool _showConfetti = false;
  WritingQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onSlot(String slotKey, String data, bool isAnswered) {
    if (isAnswered) return;

    _hapticService.success();
    setState(() {
      _slots.forEach((key, val) {
        if (val == data) {
          _slots[key] = null;
        }
      });
      _slots[slotKey] = data;
    });
  }

  void _onTapOption(String data, bool isAnswered) {
    if (isAnswered) return;

    String? targetSlot;
    for (final key in ['SUBJECT', 'SALUTATION', 'BODY', 'SIGN-OFF']) {
      if (_slots[key] == null) {
        targetSlot = key;
        break;
      }
    }

    if (targetSlot != null) {
      _hapticService.success();
      setState(() {
        _slots.forEach((key, val) {
          if (val == data) {
            _slots[key] = null;
          }
        });
        _slots[targetSlot!] = data;
      });
    } else {
      _hapticService.error();
    }
  }

  void _clearSlot(String slotKey, bool isAnswered) {
    if (isAnswered || _slots[slotKey] == null) return;
    _hapticService.selection();
    setState(() {
      _slots[slotKey] = null;
    });
  }

  void _submitAnswer(bool isAnswered) {
    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded || isAnswered) return;

    final WritingQuest? quest = state.currentQuest as WritingQuest?;
    if (quest == null) return;

    final options = quest.options ?? [];
    final correctOrderIndices = quest.correctOrder ?? [0, 1, 2, 3];

    bool isSubjectCorrect =
        _slots['SUBJECT'] == options[correctOrderIndices[0]];
    bool isSalutationCorrect =
        _slots['SALUTATION'] == options[correctOrderIndices[1]];
    bool isBodyCorrect = _slots['BODY'] == options[correctOrderIndices[2]];
    bool isSignOffCorrect =
        _slots['SIGN-OFF'] == options[correctOrderIndices[3]];

    final isCorrect =
        isSubjectCorrect &&
        isSalutationCorrect &&
        isBodyCorrect &&
        isSignOffCorrect;

    context.read<WritingBloc>().add(SubmitAnswer(isCorrect));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingGameOver && prev is! WritingGameOver) ||
          (curr is WritingLoaded && curr.lastAnswerCorrect == null),
      listener: (context, state) {
        if (state is WritingLoaded && state.lastAnswerCorrect == null) {
          setState(() {
            _slots.updateAll((k, v) => null);
            final quest = state.currentQuest;
            _shuffledOptions = List<String>.from(quest.options ?? [])
              ..shuffle();
          });
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CORRESPONDENCE ACE!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        if (isLoaded && state.currentQuest != _lastQuest) {
          _lastQuest = state.currentQuest;
        }
        final WritingQuest? quest = isLoaded ? state.currentQuest : _lastQuest;

        final options = quest?.options ?? [];
        final slotsFilled = _slots.values.every((v) => v != null);
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;

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
          showConfetti: _showConfetti,
          useScrolling: true,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: (state is WritingLoading || _lastQuest == null)
              ? GameShimmerLoading(primaryColor: theme.primaryColor)
              : quest == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 16.h),
                      WritingEmailInstruction(
                        primaryColor: theme.primaryColor,
                        instruction: quest.instruction,
                      ),
                      SizedBox(height: 24.h),

                      WritingEmailPromptCard(
                        text: quest.prompt ?? "",
                        color: theme.primaryColor,
                        isDark: isDark,
                      ),
                      SizedBox(height: 24.h),

                      ..._slots.keys.map(
                        (k) => WritingEmailHexSlot(
                          slotKey: k,
                          slotValue: _slots[k],
                          color: theme.primaryColor,
                          isDark: isDark,
                          onSlot: (key, data) => _onSlot(key, data, isAnswered),
                          onClearSlot: (key) => _clearSlot(key, isAnswered),
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
                                  slots: _slots,
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
                                .where((opt) => !_slots.values.contains(opt))
                                .toList(),
                            color: theme.primaryColor,
                            isDark: isDark,
                            onValidInput: (data) =>
                                _onTapOption(data, isAnswered),
                          ),
                        ] else
                          WritingEmailDataStream(
                            items: _shuffledOptions.isNotEmpty
                                ? _shuffledOptions
                                : options,
                            slots: _slots,
                            color: theme.primaryColor,
                            isDark: isDark,
                            onTapItem: (data) => _onTapOption(data, isAnswered),
                          ),
                        SizedBox(height: 32.h),
                      ] else ...[
                        SizedBox(height: 48.h),
                      ],

                      if (!isAnswered)
                        ScaleButton(
                          onTap: slotsFilled
                              ? () => _submitAnswer(isAnswered)
                              : null,
                          child: Container(
                            width: double.infinity,
                            height: 60.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              color: slotsFilled
                                  ? theme.primaryColor
                                  : Colors.grey,
                              boxShadow: [
                                if (slotsFilled)
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
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

                      SizedBox(height: 60.h),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
