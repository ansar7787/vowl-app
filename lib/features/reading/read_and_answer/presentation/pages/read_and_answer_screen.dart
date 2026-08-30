import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_instruction.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_anchor_point.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_buoy_option.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_floating_passage.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_result.dart';
import 'package:vowl/core/presentation/game_mechanics/evidence_highlight_wrapper.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
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

  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _showEvidenceStep = ValueNotifier(false);

  @override
  void dispose() {
    _showConfetti.dispose();
    _pendingSelectedIndex.dispose();
    _showEvidenceStep.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onOptionTap(int index, bool isCorrect, ReadingQuest quest) {
    if (_showEvidenceStep.value || _pendingSelectedIndex.value != null) return;

    _pendingSelectedIndex.value = index;

    if (isCorrect) {
      _hapticService.selection();

      // Prevent Soft-Lock: If there is no valid evidence string to highlight,
      // skip the highlight step entirely and submit the correct answer.
      final evidenceStr = (quest.evidenceLine ?? quest.correctAnswer ?? '')
          .trim();
      if (evidenceStr.isEmpty || (quest.passage ?? '').isEmpty) {
        _submitFinalAnswer(true, quest);
      } else {
        _showEvidenceStep.value = true;
      }
    } else {
      _submitFinalAnswer(false, quest);
    }
  }

  void _submitFinalAnswer(bool isCorrect, ReadingQuest quest) {
    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();

      final String userAnswer =
          (quest.options != null &&
              _pendingSelectedIndex.value != null &&
              _pendingSelectedIndex.value! < quest.options!.length)
          ? quest.options![_pendingSelectedIndex.value!]
          : 'Unknown';

      ErrorJournalCollector.record(
        userId: 'local',
        gameType: widget.gameType.name,
        question: quest.question ?? quest.instruction,
        userAnswer: userAnswer,
        correctAnswer: quest.correctAnswer ?? '',
        level: widget.level,
      );
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
          (curr is ReadingLoaded && !curr.answerStatus.isAnswered),
      listener: (context, state) {
        if (state is ReadingLoaded && !state.answerStatus.isAnswered) {
          _pendingSelectedIndex.value = null;
          _showEvidenceStep.value = false;
          _showConfetti.value = false;
        }
        if (state is ReadingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'reading_games.zen_reader',
              fallback: 'ZEN READER!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final isLoaded = state is ReadingLoaded;
        final ReadingQuest? quest = isLoaded ? state.currentQuest : null;
        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;

        String? displayTopic = quest?.paragraphTopic;
        String displayPassage = quest?.passage ?? '';

        // Automatically extract embedded tags like "[My Family]" from the passage text
        // This MUST happen at the top level so BOTH the main content and evidence wrapper sync perfectly
        if (quest != null && quest.passage != null) {
          final match = RegExp(
            r'^\[(.*?)\]\s*(.*)$',
            dotAll: true,
          ).firstMatch(quest.passage!);
          if (match != null) {
            displayTopic = match.group(1);
            displayPassage = match.group(2) ?? '';
          }
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            _showConfetti,
            _pendingSelectedIndex,
            _showEvidenceStep,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnswered,
              isCorrect: isCorrect,
              showConfetti: _showConfetti.value,
              useScrolling: false,
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
                          displayTopic: displayTopic,
                          displayPassage: displayPassage,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                          isAnswered: isAnswered,
                          isCorrect: isCorrect,
                          pendingSelectedIndex: _pendingSelectedIndex.value,
                          onOptionSelected: (idx, isCorrect) =>
                              _onOptionTap(idx, isCorrect, quest),
                        ),
                        if (_showEvidenceStep.value && !isAnswered) ...[
                          Positioned.fill(
                            child: Container(
                              color: isDark ? Colors.black87 : Colors.black.withValues(alpha: 0.6),
                            ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
                          ),
                          EvidenceHighlightWrapper(
                            passage: displayPassage,
                            // Use evidenceLine from JSON for precise pedagogical targeting
                            evidenceWords:
                                (quest.evidenceLine ??
                                        quest.correctAnswer ??
                                        '')
                                    .split(' '),
                            primaryColor: theme.primaryColor,
                            onCorrectHighlight: () =>
                                _submitFinalAnswer(true, quest),
                            instruction: 'Tap the words that prove your answer',
                          ),
                        ],
                      ],
                    ),
            );
          },
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
      label: 'Loading questionâ€¦',
      child: const SizedBox.expand(),
    );
  }
}

class _QuestContent extends StatelessWidget {
  final ReadingQuest quest;
  final String? displayTopic;
  final String displayPassage;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final int? pendingSelectedIndex;
  final void Function(int index, bool isCorrect) onOptionSelected;

  const _QuestContent({
    required this.quest,
    required this.displayTopic,
    required this.displayPassage,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.pendingSelectedIndex,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      explicitChildNodes: true,
      child: Scrollbar(
        thickness: 4.w,
        radius: Radius.circular(10.r),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ReadAndAnswerInstruction(
                          primaryColor: primaryColor,
                          instruction: displayTopic,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      _buildReadTimeBadge(primaryColor, isDark, displayPassage),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  ReadAndAnswerAnchorPoint(
                    question: quest.question ?? '',
                    color: primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  // Render Passage Box
                  ReadAndAnswerFloatingPassage(
                    text: displayPassage,
                    color: primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  if (quest.options != null)
                    ...quest.options!.asMap().entries.map((e) {
                      final isOptionCorrect =
                          e.key == quest.correctAnswerIndex ||
                          e.value.trim().toLowerCase() ==
                              (quest.correctAnswer?.trim().toLowerCase() ?? '');

                      return ReadAndAnswerBuoyOption(
                        index: e.key,
                        text: e.value,
                        isCorrectOption: isOptionCorrect,
                        color: primaryColor,
                        isDark: isDark,
                        isAnswered:
                            isAnswered || (pendingSelectedIndex != null),
                        selectedIndex: pendingSelectedIndex,
                        onTap: () => onOptionSelected(e.key, isOptionCorrect),
                      );
                    }),
                  if (isAnswered && isCorrect != null) ...[
                    SizedBox(height: 24.h),
                    ReadAndAnswerResult(
                      quest: quest,
                      isCorrect: isCorrect!,
                      isDark: isDark,
                    ),
                  ],
                  SizedBox(height: 40.h),
                ],
              ),
            ),
            SliverFillRemaining(hasScrollBody: false, child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildReadTimeBadge(
    Color primaryColor,
    bool isDark,
    String displayPassage,
  ) {
    // Avoid costly regex split in build method by relying on fast space split fallback
    final wordCount =
        quest.passageWordCount ?? (displayPassage.split(' ').length);
    // Assume 130 WPM reading speed
    final readTimeSec = (wordCount / 130 * 60).round();
    final timeStr = readTimeSec < 60
        ? '$readTimeSec sec read'
        : '${(readTimeSec / 60).round()} min read';

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 14.sp, color: primaryColor),
        SizedBox(width: 4.w),
        Text(
          timeStr.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: primaryColor,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
