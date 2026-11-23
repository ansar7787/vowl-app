import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_4way_launcher.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_sentence_slot.dart';

/// Mastery Phase Screen for Word Formation: Spatial 4-Way Morph Rush.
class WordFormationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const WordFormationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordFormation,
  });

  @override
  State<WordFormationScreen> createState() => _WordFormationScreenState();
}

class _WordFormationScreenState extends State<WordFormationScreen>
    with
        GameScreenMixin<WordFormationScreen>,
        VocabularyGameScreenMixin<WordFormationScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'MASTERY COMPLETE!';

  bool get isAnswered => isAnsweredNotifier.value;
  bool? get isCorrect => isCorrectNotifier.value;
  bool get showConfetti => showConfettiNotifier.value;

  int _shakeCount = 0;
  String? _selectedDirection;
  int _lastProcessedIndex = -1;
  int _comboStreak = 0;

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  @override
  void dispose() {
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    setState(() {
      _selectedDirection = null;
    });
  }

  String _directionFromIndex(int? index) {
    switch (index) {
      case 0:
        return 'north';
      case 1:
        return 'east';
      case 2:
        return 'south';
      case 3:
        return 'west';
      default:
        return 'north';
    }
  }

  void _onDirectionSelected(
    String direction,
    VocabularyQuest quest,
    List<String> options,
    int? correctIndex,
  ) {
    if (isAnswered) return;

    final targetDirection = _directionFromIndex(correctIndex);
    final isMatch = direction == targetDirection;
    final selectedIdx = ['north', 'east', 'south', 'west'].indexOf(direction);
    final selectedWord = (selectedIdx >= 0 && selectedIdx < options.length)
        ? options[selectedIdx]
        : '';

    setState(() {
      _selectedDirection = direction;
      if (!isMatch) {
        _shakeCount++;
      }
    });

    if (isMatch) {
      _comboStreak++;
      submitCorrectAnswer();
      final sentence = quest.sentence ?? quest.contextSentence ?? '';
      final target = quest.targetWord ?? quest.correctAnswer ?? selectedWord;
      if (sentence.isNotEmpty && target.isNotEmpty) {
        final fullText = sentence.replaceAll('_______', target);
        di.sl<TtsService>().speak(fullText);
      }
    } else {
      _comboStreak = 0;
      submitWrongAnswer(quest: quest, userAnswer: selectedWord);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    final primaryColor = theme.primaryColor;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: onVocabularyStateChanged,
      builder: (context, state) {
        if (state is! VocabularyLoaded || state.currentQuestOrNull == null) {
          return VocabularyBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: false,
            isCorrect: null,
            showConfetti: false,
            onContinue: dispatchNextQuestion,
            child: GameShimmerLoading(primaryColor: primaryColor),
          );
        }

        final quest = state.currentQuest;
        if (state.currentIndex != _lastProcessedIndex) {
          _lastProcessedIndex = state.currentIndex;
          _selectedDirection = null;
        }

        final options = quest.options ?? [];
        final rootWord = quest.rootWord ?? quest.word ?? 'ROOT';
        final sentence =
            quest.sentence ??
            quest.contextSentence ??
            'Complete the sentence with _______';
        final targetWord = quest.targetWord ?? quest.correctAnswer ?? '';
        final correctIndex = quest.correctAnswerIndex;
        final correctDir = _directionFromIndex(correctIndex);
        final targetRoleName = correctIndex == 0
            ? 'Noun'
            : (correctIndex == 1
                ? 'Adjective'
                : (correctIndex == 2 ? 'Adverb' : 'Opposite'));

        final northWord = options.isNotEmpty ? options[0] : '${rootWord}_NOUN';
        final eastWord = options.length > 1 ? options[1] : '${rootWord}_ADJ';
        final southWord = options.length > 2 ? options[2] : '${rootWord}_ADV';
        final westWord = options.length > 3 ? options[3] : '${rootWord}_OPP';

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
          ]),
          builder: (context, _) {
            final isAns = isAnsweredNotifier.value;
            final isCorr = isCorrectNotifier.value;
            final confetti = showConfettiNotifier.value;

            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAns,
              isCorrect: isCorr,
              showConfetti: confetti,
              onContinue: () {
                if (isCorr == false) {
                  isAnsweredNotifier.value = false;
                  isCorrectNotifier.value = null;
                  setState(() {
                    _selectedDirection = null;
                  });
                } else {
                  dispatchNextQuestion();
                }
              },
              onHint: () {
                dispatchHintUsed();
                di.sl<TtsService>().speak(
                  targetWord.isNotEmpty ? targetWord : rootWord,
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            SizedBox(height: 10.h),
                            WordFormationSentenceSlot(
                              sentence: sentence,
                              formedWord: isAns && isCorr == true
                                  ? targetWord
                                  : null,
                              rootWord: rootWord,
                              targetRole: targetRoleName,
                              roleClue: quest.hint,
                              isAnswered: isAns,
                              isCorrect: isCorr,
                              primaryColor: primaryColor,
                              shakeCount: _shakeCount,
                            ),
                            SizedBox(height: 16.h),
                            WordFormation4WayLauncher(
                              northWord: northWord,
                              eastWord: eastWord,
                              southWord: southWord,
                              westWord: westWord,
                              selectedDirection: _selectedDirection,
                              correctDirection: isAns ? correctDir : null,
                              isAnswered: isAns,
                              primaryColor: primaryColor,
                              comboStreak: _comboStreak,
                              onDirectionSelected: (dir) =>
                                  _onDirectionSelected(
                                    dir,
                                    quest,
                                    options,
                                    correctIndex,
                                  ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
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
