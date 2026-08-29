import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  bool _showConfetti = false;

  int? _pendingSelectedIndex;
  bool _showEvidenceStep = false;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onOptionTap(int index, bool isCorrect, ReadingQuest quest) {
    if (_showEvidenceStep || _pendingSelectedIndex != null) return;
    
    setState(() {
      _pendingSelectedIndex = index;
    });

    if (isCorrect) {
      _hapticService.selection();
      // Wait for user to tap evidence
      setState(() {
        _showEvidenceStep = true;
      });
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
      
      final String userAnswer = (quest.options != null &&
              _pendingSelectedIndex != null &&
              _pendingSelectedIndex! < quest.options!.length)
          ? quest.options![_pendingSelectedIndex!]
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
          setState(() {
            _pendingSelectedIndex = null;
            _showEvidenceStep = false;
          });
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr('reading_games.zen_reader', fallback: 'ZEN READER!'),
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

        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: _showConfetti,
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
                      primaryColor: theme.primaryColor,
                      isDark: isDark,
                      isAnswered: isAnswered,
                      isCorrect: isCorrect,
                      pendingSelectedIndex: _pendingSelectedIndex,
                      onOptionSelected: (idx, isCorrect) => _onOptionTap(idx, isCorrect, quest),
                    ),
                    if (_showEvidenceStep && !isAnswered)
                      EvidenceHighlightWrapper(
                        passage: quest.passage ?? '',
                        evidenceWords: (quest.correctAnswer ?? '').split(' '),
                        primaryColor: theme.primaryColor,
                        onCorrectHighlight: () => _submitFinalAnswer(true, quest),
                        instruction: 'Tap the words that prove your answer',
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
      label: 'Loading questionâ€¦',
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
  final int? pendingSelectedIndex;
  final void Function(int index, bool isCorrect) onOptionSelected;

  const _QuestContent({
    required this.quest,
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
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: 0, // Padding is handled by ReadingContentArea
              vertical: 0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 16.h),
                  ReadAndAnswerInstruction(
                    primaryColor: primaryColor,
                    instruction: quest.instruction,
                  ),
                  SizedBox(height: 16.h),
                  _buildReadTimeBadge(primaryColor, isDark),
                  SizedBox(height: 16.h),
                  ReadAndAnswerAnchorPoint(
                    question: quest.question ?? '',
                    color: primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  // Render Passage Box
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      quest.passage ?? '',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                        height: 1.65,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  if (quest.options != null)
                    ...quest.options!.asMap().entries.map((e) {
                      final isOptionCorrect = e.key == quest.correctAnswerIndex ||
                          e.value.trim().toLowerCase() == (quest.correctAnswer?.trim().toLowerCase() ?? '');
                      
                      return ReadAndAnswerBuoyOption(
                        index: e.key,
                        text: e.value,
                        correct: quest.correctAnswer ?? '',
                        color: primaryColor,
                        isDark: isDark,
                        isAnswered: isAnswered || (pendingSelectedIndex != null),
                        selectedIndex: pendingSelectedIndex,
                        onTap: () => onOptionSelected(e.key, isOptionCorrect),
                      );
                    }),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadTimeBadge(Color primaryColor, bool isDark) {
    final wordCount = quest.passageWordCount ?? quest.passage?.split(RegExp(r'\s+')).length ?? 50;
    // Assume 130 WPM reading speed
    final readTimeSec = (wordCount / 130 * 60).round();
    final timeStr = readTimeSec < 60 ? '$readTimeSec sec read' : '${(readTimeSec/60).round()} min read';
    
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
