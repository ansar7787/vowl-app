import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_instruction.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_floating_passage.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_anchor_point.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_buoy_option.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_result.dart';
import 'package:vowl/core/presentation/widgets/speak_to_confirm_overlay.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

class ReadAndAnswerScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const ReadAndAnswerScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readAndAnswer,
  });

  @override
  State<ReadAndAnswerScreen> createState() => _ReadAndAnswerScreenState();
}

class _ReadAndAnswerScreenState extends State<ReadAndAnswerScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int? _selectedIndex;
  int? _pendingSelectedIndex;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onOptionTap(int index) {
    if (_selectedIndex != null || _pendingSelectedIndex != null) return;
    setState(() => _pendingSelectedIndex = index);
  }

  void _submitFinalAnswer(bool nailedSpeaking, ReadingQuest quest) {
    if (_pendingSelectedIndex == null) return;

    if (!nailedSpeaking) {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _selectedIndex = _pendingSelectedIndex;
      });
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      return;
    }

    final selected = quest.options![_pendingSelectedIndex!];
    final isCorrect = selected.trim().toLowerCase() == (quest.correctAnswer ?? '').trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _selectedIndex = _pendingSelectedIndex;
      });
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _selectedIndex = _pendingSelectedIndex;
      });
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      isDark: isDark,
    );

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: (prev, curr) =>
          (curr is ReadingGameComplete && prev is! ReadingGameComplete) ||
          (curr is ReadingGameOver && prev is! ReadingGameOver) ||
          (curr is ReadingLoaded && curr.lastAnswerCorrect == null),
      listener: (context, state) {
        if (state is ReadingLoaded && state.lastAnswerCorrect == null) {
          setState(() {
            _selectedIndex = null;
            _pendingSelectedIndex = null;
          });
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'ZEN READER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final isLoaded = state is ReadingLoaded;
        final ReadingQuest? quest = isLoaded ? state.currentQuest : null;
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;

        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: _showConfetti,
          useScrolling: true,
          onContinue: () =>
              context.read<ReadingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<ReadingBloc>().add(const ReadingHintUsed()),
          child: quest == null
              ? const _QuestLoadingPlaceholder()
              : Stack(
                  children: [
                    _QuestContent(
                      quest: quest,
                      primaryColor: theme.primaryColor,
                      isDark: isDark,
                      isAnswered: isAnswered,
                      isCorrect: isCorrect,
                      selectedIndex: _selectedIndex ?? _pendingSelectedIndex,
                      onOptionTap: _onOptionTap,
                    ),
                    if (_pendingSelectedIndex != null && !isAnswered)
                      SpeakToConfirmOverlay(
                        expectedText: quest.options![_pendingSelectedIndex!],
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true, quest),
                        onSkipped: () => _submitFinalAnswer(false, quest),
                        allowSkip: true,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _QuestLoadingPlaceholder extends StatelessWidget {
  const _QuestLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading question…',
      child: const SizedBox.expand(),
    );
  }
}

class _QuestContent extends StatelessWidget {
  final ReadingQuest quest;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final int? selectedIndex;
  final void Function(int) onOptionTap;

  const _QuestContent({
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedIndex,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    final options = quest.options ?? const [];

    return Semantics(
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.h),
          ReadAndAnswerInstruction(
            primaryColor: primaryColor,
            instruction: quest.instruction,
          ),
          SizedBox(height: 24.h),
          ReadAndAnswerFloatingPassage(
            text: quest.passage ?? '',
            color: primaryColor,
            isDark: isDark,
          ),
          SizedBox(height: 32.h),
          ReadAndAnswerAnchorPoint(
            question: quest.question ?? '',
            color: primaryColor,
            isDark: isDark,
          ),
          SizedBox(height: 32.h),
          ...List.generate(options.length, (index) {
            final optionText = options[index];
            return ReadAndAnswerBuoyOption(
              index: index,
              text: optionText,
              correct: quest.correctAnswer ?? '',
              color: primaryColor,
              isDark: isDark,
              isAnswered: isAnswered,
              selectedIndex: selectedIndex,
              onTap: () => onOptionTap(index),
            );
          }),
          if (isAnswered) ...[
            SizedBox(height: 24.h),
            ReadAndAnswerResult(
              quest: quest,
              isCorrect: isCorrect == true,
              isDark: isDark,
            ),
          ],
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}
