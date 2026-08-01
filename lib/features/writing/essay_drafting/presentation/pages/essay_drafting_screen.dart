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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_instruction.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_topic_banner.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_hex_slot.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_data_stream.dart';

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

class _EssayDraftingScreenState extends State<EssayDraftingScreen> {
  final _hapticService = di.sl<HapticService>();

  final Map<String, String?> _blueprintSlots = {};
  WritingQuest? _lastQuest;
  List<String> _shuffledOptions = [];

  bool _showConfetti = false;

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
      _blueprintSlots.forEach((key, val) {
        if (val == data) {
          _blueprintSlots[key] = null;
        }
      });
      _blueprintSlots[slotKey] = data;
    });
  }

  void _clearSlot(String slotKey, bool isAnswered) {
    if (isAnswered || _blueprintSlots[slotKey] == null) return;
    _hapticService.selection();
    setState(() {
      _blueprintSlots[slotKey] = null;
    });
  }

  void _submitAnswer(bool isAnswered) {
    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded || isAnswered) return;

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
        _blueprintSlots[points[0]] == options[correctOrderIndices[0]];
    bool isSlot1Correct =
        _blueprintSlots[points[1]] == options[correctOrderIndices[1]];
    bool isSlot2Correct =
        _blueprintSlots[points[2]] == options[correctOrderIndices[2]];
    bool isSlot3Correct =
        _blueprintSlots[points[3]] == options[correctOrderIndices[3]];

    final isCorrect =
        isSlot0Correct && isSlot1Correct && isSlot2Correct && isSlot3Correct;

    context.read<WritingBloc>().add(SubmitAnswer(isCorrect));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingLoaded && curr.lastAnswerCorrect == null),
      listener: (context, state) {
        if (state is WritingLoaded && state.lastAnswerCorrect == null) {
          setState(() {
            _blueprintSlots.clear();
            final quest = state.currentQuest;
            for (var point in (quest.requiredPoints ?? [])) {
              _blueprintSlots[point] = null;
            }
            _shuffledOptions = List<String>.from(quest.options ?? [])..shuffle();
          });
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'ESSAY ARCHITECT!',
            enableDoubleUp: true,
          );
        }
      },
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
        final slotsFilled =
            _blueprintSlots.values.every((v) => v != null) &&
            _blueprintSlots.isNotEmpty;
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;
        final bool isFinalFailure = state.livesRemaining == 0;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: activeQuest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                        SizedBox(height: 24.h),

                        ..._blueprintSlots.keys.map(
                          (k) => EssayDraftingHexSlot(
                            slotKey: k,
                            slotValue: _blueprintSlots[k],
                            color: theme.primaryColor,
                            isDark: isDark,
                            onSlot: (key, data) =>
                                _onSlot(key, data, isAnswered),
                            onClearSlot: (key) => _clearSlot(key, isAnswered),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        EssayDraftingDataStream(
                          items: _shuffledOptions.isNotEmpty ? _shuffledOptions : options,
                          slots: _blueprintSlots,
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 16.h),

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
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}


