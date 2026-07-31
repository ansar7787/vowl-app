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

import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/models/describe_frame_slot.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_writing_instruction.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_manuscript.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_film_strip.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_frame_vault.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_projector_crank.dart';

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

  final List<DescribeFrameSlot> _slots = [
    DescribeFrameSlot(index: 0),
    DescribeFrameSlot(index: 1),
    DescribeFrameSlot(index: 2),
  ];

  bool _showConfetti = false;
  double _crankProgress = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onDropFrame(int slotIdx, String sentence, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.success();
    setState(() {
      _slots[slotIdx].sentence = sentence;
    });
  }

  void _removeFrame(int slotIdx, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.selection();
    setState(() {
      _slots[slotIdx].sentence = null;
      _crankProgress = 0.0;
    });
  }

  void _onCrank(double delta, bool isAnswered) {
    if (isAnswered) return;

    final isSlotsFilled = _slots.every((s) => s.sentence != null);
    if (!isSlotsFilled) return;

    setState(() {
      _crankProgress = (_crankProgress + delta.abs() / 450).clamp(0.0, 1.0);
    });

    if (_crankProgress % 0.15 < 0.02) {
      _hapticService.selection();
    }

    if (_crankProgress >= 1.0) {
      _submitAnswer(isAnswered);
    }
  }

  void _submitAnswer(bool isAnswered) {
    if (isAnswered) return;

    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded) return;

    final WritingQuest? quest = state.currentQuest as WritingQuest?;
    if (quest == null) return;

    final options = quest.options ?? [];
    final correctIndices = quest.correctOrder ?? [0, 1, 2];

    bool isAllCorrect = true;
    for (int i = 0; i < 3; i++) {
      final slotSentence = _slots[i].sentence;
      final targetIdx = correctIndices[i];
      final targetSentence = options[targetIdx];

      if (slotSentence != targetSentence) {
        isAllCorrect = false;
        break;
      }
    }

    context.read<WritingBloc>().add(SubmitAnswer(isAllCorrect));
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
            _crankProgress = 0.0;
            for (var slot in _slots) {
              slot.sentence = null;
            }
          });
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
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
        final WritingQuest? quest = isLoaded
            ? state.currentQuest as WritingQuest?
            : null;

        final options = quest?.options ?? [];
        final isSlotsFilled = _slots.every((s) => s.sentence != null);
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        SummarizeStoryWritingInstruction(
                          instruction: quest.instruction,
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
                          slots: _slots,
                          color: theme.primaryColor,
                          isDark: isDark,
                          onDropFrame: (idx, sentence) =>
                              _onDropFrame(idx, sentence, isAnswered),
                          onRemoveFrame: (idx) => _removeFrame(idx, isAnswered),
                        ),
                        SizedBox(height: 24.h),

                        SummarizeStoryFrameVault(
                          options: options,
                          slots: _slots,
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 32.h),

                        if (isSlotsFilled && !isAnswered)
                          SummarizeStoryProjectorCrank(
                            crankProgress: _crankProgress,
                            color: theme.primaryColor,
                            isDark: isDark,
                            onCrank: (delta) => _onCrank(delta, isAnswered),
                          ),

                        SizedBox(height: 60.h),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}


