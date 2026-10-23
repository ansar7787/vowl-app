import 'dart:async';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_instruction.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_diagnostic_word.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_options_panel.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_feedback.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class SentenceCorrectionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SentenceCorrectionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceCorrection,
  });

  @override
  State<SentenceCorrectionScreen> createState() =>
      _SentenceCorrectionScreenState();
}

class _SentenceCorrectionScreenState extends State<SentenceCorrectionScreen>
    with
        GameScreenMixin<SentenceCorrectionScreen>,
        GrammarGameScreenMixin<SentenceCorrectionScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<int?> _selectedWordIndex = ValueNotifier(null);
  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  List<String>? _shuffledOptions;

  // States

  // Detailed feedback states
  final ValueNotifier<bool?> _wordSelectionCorrect = ValueNotifier(null);
  final ValueNotifier<bool?> _optionSelectionCorrect = ValueNotifier(null);

  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _selectedWordIndex.dispose();
    _selectedOption.dispose();
    _wordSelectionCorrect.dispose();
    _optionSelectionCorrect.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  void _scrollToBottom() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initGrammarGame();
  }

  List<int> _getCorrectIndices(List<String> words, GrammarQuest quest) {
    if (quest.incorrectPart == null) return [0];

    final cleanTarget = quest.incorrectPart!
        .toLowerCase()
        .replaceAll('"', '')
        .trim();
    final targetWords = cleanTarget
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    if (targetWords.isEmpty) return [0];

    final cleanSentenceWords = words
        .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^\w]'), ''))
        .toList();
    final cleanTargetWords = targetWords
        .map((w) => w.replaceAll(RegExp(r'[^\w]'), ''))
        .toList();

    List<int> matchingIndices = [];

    // Contiguous search match
    for (
      int i = 0;
      i <= cleanSentenceWords.length - cleanTargetWords.length;
      i++
    ) {
      bool match = true;
      for (int j = 0; j < cleanTargetWords.length; j++) {
        if (!cleanSentenceWords[i + j].contains(cleanTargetWords[j]) &&
            !cleanTargetWords[j].contains(cleanSentenceWords[i + j])) {
          match = false;
          break;
        }
      }
      if (match) {
        for (int j = 0; j < cleanTargetWords.length; j++) {
          matchingIndices.add(i + j);
        }
        break;
      }
    }

    if (matchingIndices.isEmpty) {
      for (int i = 0; i < cleanSentenceWords.length; i++) {
        for (var targetW in cleanTargetWords) {
          if (cleanSentenceWords[i] == targetW ||
              (cleanSentenceWords[i].isNotEmpty &&
                  targetW.contains(cleanSentenceWords[i]))) {
            matchingIndices.add(i);
          }
        }
      }
    }

    if (matchingIndices.isEmpty) {
      final fallbackIdx = words.indexWhere((w) {
        final cleanW = w.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        return cleanW.contains(cleanTargetWords.first) ||
            cleanTargetWords.first.contains(cleanW);
      });
      matchingIndices.add(fallbackIdx != -1 ? fallbackIdx : 0);
    }

    return matchingIndices;
  }

  void _onWordTap(int index) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    _selectedWordIndex.value = index;
    _selectedOption.value = null;
  }

  void _confirmRepair(
    List<int> correctIndices,
    GrammarQuest quest,
    List<String> words,
  ) {
    if (_selectedWordIndex.value == null || _selectedOption.value == null) {
      return;
    }

    bool isWordCorrect = correctIndices.contains(_selectedWordIndex.value);
    int chosenIndex = quest.options?.indexOf(_selectedOption.value!) ?? -1;
    bool isOptionCorrect =
        (_selectedOption.value == quest.correctAnswer) ||
        (chosenIndex == quest.correctAnswerIndex);
    bool overallCorrect = isWordCorrect && isOptionCorrect;

    _wordSelectionCorrect.value = isWordCorrect;
    _optionSelectionCorrect.value = isOptionCorrect;

    if (overallCorrect) {
      hapticService.heavy();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      submitWrongAnswer(quest: quest, userAnswer: '');
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: '');
    }
  }

  @override
  void onQuestionReset() {
    _scrollTimer?.cancel();
    _selectedWordIndex.value = null;
    _selectedOption.value = null;
    _wordSelectionCorrect.value = null;
    _optionSelectionCorrect.value = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final rawSentence = quest?.sentence ?? "";
        final cleanSentence = rawSentence
            .replaceAll('"', '')
            .replaceAll('Fix:', '')
            .trim();
        final words = cleanSentence
            .split(' ')
            .where((w) => w.isNotEmpty)
            .toList();

        if (quest != null && _shuffledOptions == null) {
          _shuffledOptions = List<String>.from(quest.options ?? []);
          _shuffledOptions!.shuffle();
        }

        final List<int> correctIndices = quest == null
            ? []
            : _getCorrectIndices(words, quest);

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _selectedWordIndex,
            _selectedOption,
            isFirstStagePassedNotifier,
            _wordSelectionCorrect,
            _optionSelectionCorrect,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              disablePadding: true,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
              onHint: () {},
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          crossAxisMargin:
                              2, // Pushes it completely to the right edge
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                              SliverToBoxAdapter(
                                child: IgnorePointer(
                                  ignoring: isFirstStagePassedNotifier.value,
                                  child: Column(
                                    children: [
                                      SizedBox(height: 10.h),
                                      SentenceCorrectionInstruction(
                                        primaryColor: theme.primaryColor,
                                        instruction:
                                            quest.instruction.trim().isNotEmpty
                                                ? quest.instruction.trim()
                                                : "Sentence Correction",
                                      ),
                                      SizedBox(height: 12.h),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24.w,
                                        ),
                                        child: Text(
                                          "Tap the incorrect word, then choose the correct replacement.",
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 13.5.sp,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),

                                      // Diagnostic Context Card
                                      Builder(
                                        builder: (context) {
                                          final card = Padding(
                                            key: const ValueKey(
                                              'sentence_correction_context_card',
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24.w,
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20.w,
                                                vertical: 22.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.05,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.03,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(24.r),
                                                border: Border.all(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.18),
                                                  width: 1.2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: theme.primaryColor
                                                        .withValues(
                                                          alpha: 0.04,
                                                        ),
                                                    blurRadius: 24,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 8.w,
                                                runSpacing: 12.h,
                                                children: List.generate(
                                                  words.length,
                                                  (i) {
                                                    bool isTargetWord =
                                                        correctIndices.contains(
                                                          i,
                                                        );
                                                    bool isSelectedWord =
                                                        _selectedWordIndex
                                                            .value ==
                                                        i;

                                                    bool isCorrectZap = false;
                                                    bool isWrongZap = false;

                                                    if (isAnsweredNotifier
                                                        .value) {
                                                      if (isCorrectNotifier
                                                              .value ==
                                                          true) {
                                                        if (isTargetWord) {
                                                          isCorrectZap = true;
                                                        }
                                                      } else {
                                                        if (isFirstStagePassedNotifier
                                                            .value) {
                                                          if (isTargetWord) {
                                                            isCorrectZap = true;
                                                          }
                                                        } else {
                                                          if (isSelectedWord &&
                                                              !isTargetWord) {
                                                            isWrongZap = true;
                                                          }
                                                          if (isTargetWord) {
                                                            isCorrectZap = true;
                                                          }
                                                        }
                                                      }
                                                    }

                                                    return SentenceCorrectionDiagnosticWord(
                                                      text: words[i],
                                                      index: i,
                                                      isSuspected:
                                                          isSelectedWord,
                                                      isCorrectZap:
                                                          isCorrectZap,
                                                      isWrongZap: isWrongZap,
                                                      isErrorHighlight: false,
                                                      isDark: isDark,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      onTap: () =>
                                                          _onWordTap(i),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                          if (reduceMotion) return card;
                                          return card
                                              .animate()
                                              .fadeIn(duration: 800.ms)
                                              .slideY(begin: 0.1, end: 0);
                                        },
                                      ),

                                      SizedBox(height: 20.h),

                                      // Status Hint
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24.w,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Builder(
                                              builder: (context) {
                                                final dot = Container(
                                                  width: 8.r,
                                                  height: 8.r,
                                                  decoration: BoxDecoration(
                                                    color: theme.primaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                );
                                                if (reduceMotion) return dot;
                                                return dot
                                                    .animate(
                                                      onPlay: (c) => c.repeat(
                                                        reverse: true,
                                                      ),
                                                    )
                                                    .scale(
                                                      begin: const Offset(1, 1),
                                                      end: const Offset(
                                                        1.3,
                                                        1.3,
                                                      ),
                                                      duration: 1.seconds,
                                                    );
                                              },
                                            ),
                                            SizedBox(width: 8.w),
                                            Flexible(
                                              child: Text(
                                                _selectedWordIndex.value == null
                                                    ? "Tap the word with the mistake"
                                                    : "Choose the correct replacement below",
                                                textAlign: TextAlign.center,
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12.5.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.primaryColor,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Options Panel
                                      if (_selectedWordIndex.value != null) ...[
                                        SizedBox(height: 24.h),
                                        SentenceCorrectionOptionsPanel(
                                          key: const ValueKey(
                                            'sentence_correction_options_panel',
                                          ),
                                          options: _shuffledOptions ?? [],
                                          selectedOption: _selectedOption.value,
                                          isAnswered:
                                              isAnsweredNotifier.value &&
                                              (isCorrectNotifier.value !=
                                                      null ||
                                                  !isFirstStagePassedNotifier
                                                      .value),
                                          isDark: isDark,
                                          primaryColor: theme.primaryColor,
                                          onOptionSelect: (option) {
                                            hapticService.selection();
                                            _selectedOption.value = option;
                                          },
                                          onConfirm: () => _confirmRepair(
                                            correctIndices,
                                            quest,
                                            words,
                                          ),
                                        ),
                                      ],

                                      // Correction Feedback
                                      if (isAnsweredNotifier.value &&
                                          isCorrectNotifier.value == false) ...[
                                        SizedBox(height: 24.h),
                                        SentenceCorrectionFeedback(
                                          key: const ValueKey(
                                            'sentence_correction_feedback',
                                          ),
                                          correction: quest.correctedPart ?? "",
                                          incorrectPart: quest.incorrectPart,
                                          wasWordSelectionCorrect:
                                              _wordSelectionCorrect.value ??
                                              false,
                                          wasOptionSelectionCorrect:
                                              _optionSelectionCorrect.value ??
                                              false,
                                          primaryColor: theme.primaryColor,
                                        ),
                                      ],

                                      SizedBox(height: 20.h),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      (isFirstStagePassedNotifier.value &&
                                          !isAnsweredNotifier.value)
                                      ? 32.h
                                      : 60.h,
                                ),
                              ),
                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                    ),
                                    child: TypeToConfirmOverlay(
                                      expectedText:
                                          quest.correctAnswer ??
                                          _selectedOption.value ??
                                          '',
                                      primaryColor: theme.primaryColor,
                                      onConfirmed: () =>
                                          _submitVerbalEvaluation(true, quest),
                                      onSkipped: () =>
                                          _submitVerbalEvaluation(false, quest),
                                      isPositioned: false,
                                    ),
                                  ),
                                ),
                              // Buffer to accommodate the keyboard popping up seamlessly without obscuring the typing card.
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom >
                                          0
                                      ? MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            40.h
                                      : 120.h,
                                ),
                              ),
                            ],
                          ),
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
