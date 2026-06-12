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
  // ---------------------------------------------------------------------------
  // Local UI state — only what cannot be derived from the BLoC.
  //
  // _isAnswered, _isCorrect, _lastProcessedIndex, _lastLives were all removed:
  // they are now derived from ReadingLoaded.lastAnswerCorrect, which is the
  // single source of truth and eliminates a whole class of sync bugs.
  // ---------------------------------------------------------------------------

  /// Which option index the player tapped. Null until an option is chosen.
  /// Reset to null whenever the BLoC signals a new question or a retry.
  int? _selectedIndex;

  /// Drives the confetti overlay in [ReadingBaseLayout]. Latched to true on
  /// [ReadingGameComplete] and never reset (stays for the completion dialog).
  bool _showConfetti = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  // ---------------------------------------------------------------------------
  // Interaction
  // ---------------------------------------------------------------------------

  /// Handles an option tap. Sound and haptic feedback are intentionally
  /// NOT called here — the BLoC's [SubmitAnswer] handler owns audio/haptic
  /// to guarantee they fire exactly once regardless of tap rate.
  ///
  /// [_selectedIndex] is set immediately so the pressed option highlights
  /// in the same frame. The BLoC processes the event synchronously, so
  /// [isAnswered] (derived from [state.lastAnswerCorrect]) updates in the
  /// same build pass — no visible flicker between selection and feedback.
  void _onOptionTap(int index, String selected, String correct) {
    // Guard: ignore subsequent taps once an option has been chosen.
    if (_selectedIndex != null) return;
    setState(() => _selectedIndex = index);
    final isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();
    context.read<ReadingBloc>().add(SubmitAnswer(isCorrect));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Match the call signature used by ReadingBaseLayout so both widgets
    // resolve the same theme object. The original used 'reading' + level:
    // which ignored isDark and used a potentially wrong game-type string.
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      isDark: isDark,
    );

    return BlocConsumer<ReadingBloc, ReadingState>(
      // Only invoke the listener when:
      //  (a) a terminal state is reached for the first time, or
      //  (b) the question resets (lastAnswerCorrect returns to null).
      // Without listenWhen, the listener would re-fire on local setState
      // rebuilds (e.g. _showConfetti = true), potentially showing dialogs twice.
      listenWhen: (prev, curr) =>
          (curr is ReadingGameComplete && prev is! ReadingGameComplete) ||
          (curr is ReadingGameOver && prev is! ReadingGameOver) ||
          (curr is ReadingLoaded && curr.lastAnswerCorrect == null),
      listener: (context, state) {
        if (state is ReadingLoaded && state.lastAnswerCorrect == null) {
          // New question loaded or retry triggered — clear the selected option.
          setState(() => _selectedIndex = null);
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
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () =>
                context.read<ReadingBloc>().add(const RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        // Derive answer state from the BLoC — no local mirrors needed.
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
              : _QuestContent(
                  quest: quest,
                  primaryColor: theme.primaryColor,
                  isDark: isDark,
                  isAnswered: isAnswered,
                  isCorrect: isCorrect,
                  selectedIndex: _selectedIndex,
                  onOptionTap: _onOptionTap,
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// Shown while the first quest is loading. Keeps the layout stable so
/// [ReadingBaseLayout] renders its scaffold and header immediately.
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

/// Renders the full question UI for a loaded [ReadingQuest].
///
/// Extracted to a [StatelessWidget] so Flutter's element diffing can detect
/// that nothing changed when only BLoC state irrelevant to this subtree
/// (e.g. hint-used flag) changes, avoiding unnecessary rebuilds.
class _QuestContent extends StatelessWidget {
  final ReadingQuest quest;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final int? selectedIndex;
  final void Function(int, String, String) onOptionTap;

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
      // Group the entire question UI so screen readers can navigate as a unit.
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.h),
          ReadAndAnswerInstruction(primaryColor: primaryColor),
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

          // Options — null-safe: options is normalised to [] above.
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
              onTap: () =>
                  onOptionTap(index, optionText, quest.correctAnswer ?? ''),
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
