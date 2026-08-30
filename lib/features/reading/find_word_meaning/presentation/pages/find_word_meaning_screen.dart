import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_instruction.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_question_header.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_result.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_interactive_passage.dart';
import 'package:vowl/core/presentation/game_mechanics/context_sentence_builder.dart';
import 'package:vowl/core/services/error_journal_collector.dart';

class FindWordMeaningScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FindWordMeaningScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.findWordMeaning,
  });

  @override
  State<FindWordMeaningScreen> createState() => _FindWordMeaningScreenState();
}

class _FindWordMeaningScreenState extends State<FindWordMeaningScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _scrollController = ScrollController();

  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _showSentenceBuilder = ValueNotifier(false);
  final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showConfetti.dispose();
    _showSentenceBuilder.dispose();
    _pendingSelectedIndex.dispose();
    super.dispose();
  }

  void _submitFinalAnswer(bool isCorrect, int index, [ReadingQuest? quest]) {
    if (_showSentenceBuilder.value || _pendingSelectedIndex.value != null) return;

    _pendingSelectedIndex.value = index;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _showSentenceBuilder.value = true;
    } else {
      _hapticService.error();
      _soundService.playWrong();
      
      if (quest != null) {
        ErrorJournalCollector.record(
          userId: 'local',
          gameType: widget.gameType.name,
          question: quest.question ?? quest.instruction,
          userAnswer: 'Incorrect meaning selected',
          correctAnswer: quest.correctAnswer ?? '',
          level: widget.level,
        );
      }
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _onSentenceBuilderComplete() {
    _showSentenceBuilder.value = false;
    context.read<ReadingBloc>().add(const SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded && !state.answerStatus.isAnswered) {
          // Reset local UI state for a new question or retry
          _pendingSelectedIndex.value = null;
          _showSentenceBuilder.value = false;
          _showConfetti.value = false;
          
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
            );
          }
        }
        
        if (state is ReadingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr('reading_games.lexical_master', fallback: 'LEXICAL MASTER!'),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final isLoaded = state is ReadingLoaded;
        final ReadingQuest? quest = isLoaded ? state.currentQuest as ReadingQuest? : null;
        final bool isAnsweredBloc = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrectBloc = isLoaded ? state.answerStatus.asBoolOrNull : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _showConfetti,
            _showSentenceBuilder,
            _pendingSelectedIndex,
          ]),
          builder: (context, _) {
            // Computed state
            // If sentence builder is showing, the question is NOT finished yet.
            final bool isAnswered = isAnsweredBloc || (_pendingSelectedIndex.value != null && !_showSentenceBuilder.value);
            final bool? isCorrect = _showSentenceBuilder.value ? true : isCorrectBloc;

            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnswered,
              isCorrect: isCorrect,
              showConfetti: _showConfetti.value,
              disablePadding: true,
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<ReadingBloc>().add(const ReadingHintUsed()),
              child: quest == null
                  ? const SizedBox()
                  : Stack(
                      children: [
                        Scrollbar(
                          thickness: 4.w,
                          radius: Radius.circular(10.r),
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
                                    FindWordMeaningInstruction(
                                      primaryColor: theme.primaryColor,
                                      instruction: quest.instruction,
                                    ),
                                    SizedBox(height: 24.h),
                                    FindWordMeaningQuestionHeader(
                                      text: quest.question ?? "",
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                    ),
                                    SizedBox(height: 32.h),
                                    FindWordMeaningInteractivePassage(
                                      passage: quest.passage ?? "",
                                      targetWord: quest.targetWord ?? "",
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      isAnswered: isAnswered,
                                      selectedIndex: _pendingSelectedIndex.value,
                                      isCorrectSelection: isCorrect,
                                      onWordSelected: (isCorrectTap, word, index) {
                                        _submitFinalAnswer(isCorrectTap, index, quest);
                                      },
                                    ),
                                    if (isAnsweredBloc) ...[
                                      SizedBox(height: 30.h),
                                      FindWordMeaningResult(
                                        quest: quest,
                                        isCorrect: isCorrect == true,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(height: 50.h),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ),
                        if (_showSentenceBuilder.value)
                          ContextSentenceBuilder(
                            targetKeyword: quest.word ?? '',
                            primaryColor: theme.primaryColor,
                            onConfirmed: _onSentenceBuilderComplete,
                            onSkipped: _onSentenceBuilderComplete,
                            allowSkip: true,
                            bonusCoins: 5,
                            exampleSentence: quest.wordInContext,
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

