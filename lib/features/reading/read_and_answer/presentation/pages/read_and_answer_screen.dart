import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/mixins/reading_game_screen_mixin.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_instruction.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_anchor_point.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_buoy_option.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/widgets/read_and_answer_floating_passage.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';

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

class _ReadAndAnswerScreenState extends State<ReadAndAnswerScreen>
    with
        GameScreenMixin<ReadAndAnswerScreen>,
        ReadingGameScreenMixin<ReadAndAnswerScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _showEvidenceStep = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _showEvidenceStep.removeListener(_scrollToBottom);
    _pendingSelectedIndex.dispose();
    _showEvidenceStep.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initReadingGame();
    _showEvidenceStep.addListener(_scrollToBottom);
  }

  void _scrollToBottom() {
    if (_showEvidenceStep.value && mounted && _scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _onOptionTap(
    int index,
    bool isCorrect,
    ReadingQuest quest,
    String displayPassage,
  ) {
    if (_showEvidenceStep.value ||
        _pendingSelectedIndex.value != null ||
        isAnsweredNotifier.value)
      return;

    _pendingSelectedIndex.value = index;

    if (isCorrect) {
      hapticService.selection();

      // Prevent Soft-Lock & Bad UX:
      // Only show evidence step if the evidence string actually exists exactly in the passage.
      // Otherwise, the fallback bag-of-words highlighting forces finding every disjointed word,
      // which is pedagogically flawed and frustrating for non-exact matches.
      final evidenceStr = (quest.evidenceLine ?? quest.correctAnswer ?? '')
          .trim();
      final hasExactMatch = displayPassage.toLowerCase().contains(
        evidenceStr.toLowerCase(),
      );

      if (evidenceStr.isEmpty || displayPassage.isEmpty || !hasExactMatch) {
        _submitFinalAnswer(true, quest);
      } else {
        _showEvidenceStep.value = true;
      }
    } else {
      _submitFinalAnswer(false, quest);
    }
  }

  void _submitFinalAnswer(bool isCorrect, ReadingQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      final String userAnswer =
          (quest.options != null &&
              _pendingSelectedIndex.value != null &&
              _pendingSelectedIndex.value! < quest.options!.length)
          ? quest.options![_pendingSelectedIndex.value!]
          : 'Unknown';

      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  @override
  void onQuestionReset() {
    _pendingSelectedIndex.value = null;
    _showEvidenceStep.value = false;
  }

  Widget _buildReadTimeBadge(
    Color primaryColor,
    bool isDark,
    String displayPassage,
    int? passageWordCount,
  ) {
    final wordCount = passageWordCount ?? (displayPassage.split(' ').length);
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
      listener: onReadingStateChanged,
      builder: (context, state) {
        final isLoaded = state is ReadingLoaded;
        final ReadingQuest? quest = isLoaded ? state.currentQuest : null;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;

        String? displayTopic = quest?.paragraphTopic;
        String displayPassage = quest?.passage ?? '';

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
            showConfettiNotifier,
            _pendingSelectedIndex,
            _showEvidenceStep,
            isAnsweredNotifier,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value ?? isCorrect,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              disablePadding: true,
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<ReadingBloc>().add(const ReadingHintUsed()),
              child: quest == null
                  ? Semantics(
                      label: 'Loading question…',
                      child: const SizedBox.expand(),
                    )
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: 16.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: ReadAndAnswerInstruction(
                                          primaryColor: theme.primaryColor,
                                          instruction: displayTopic,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      _buildReadTimeBadge(
                                        theme.primaryColor,
                                        isDark,
                                        displayPassage,
                                        quest.passageWordCount,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  ReadAndAnswerAnchorPoint(
                                    question: quest.question ?? '',
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 24.h),
                                  ReadAndAnswerFloatingPassage(
                                    text: displayPassage,
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 24.h),
                                  if (quest.options != null)
                                    ...quest.options!.asMap().entries.map((e) {
                                      final isOptionCorrect =
                                          e.key == quest.correctAnswerIndex ||
                                          e.value.trim().toLowerCase() ==
                                              (quest.correctAnswer
                                                      ?.trim()
                                                      .toLowerCase() ??
                                                  '');

                                      return ReadAndAnswerBuoyOption(
                                        index: e.key,
                                        text: e.value,
                                        isCorrectOption: isOptionCorrect,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        isAnswered:
                                            isAnsweredNotifier.value ||
                                            (_pendingSelectedIndex.value !=
                                                null),
                                        selectedIndex:
                                            _pendingSelectedIndex.value,
                                        onTap: () => _onOptionTap(
                                          e.key,
                                          isOptionCorrect,
                                          quest,
                                          displayPassage,
                                        ),
                                      );
                                    }),

                                  // Give space if Phase 2 is hidden, otherwise let Phase 2 dictate height
                                  if (!_showEvidenceStep.value)
                                    SizedBox(height: 120.h),

                                  if (_showEvidenceStep.value &&
                                      !isAnsweredNotifier.value)
                                    SizedBox(height: 32.h),
                                ],
                              ),
                            ),
                          ),

                          if (_showEvidenceStep.value &&
                              !isAnsweredNotifier.value)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child:
                                    EvidenceHighlightWrapper(
                                      passage: displayPassage,
                                      evidenceWords: [
                                        quest.evidenceLine ??
                                            quest.correctAnswer ??
                                            '',
                                      ],
                                      primaryColor: theme.primaryColor,
                                      onCorrectHighlight: () =>
                                          _submitFinalAnswer(true, quest),
                                      instruction:
                                          'Tap the words that prove your answer',
                                      isPositioned: false,
                                    ).animate().fadeIn(
                                      duration: 400.ms,
                                      curve: Curves.easeOut,
                                    ),
                              ),
                            ),

                          if (_showEvidenceStep.value)
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
                    ),
            );
          },
        );
      },
    );
  }
}
