import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
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

  static const int _maxTimeSeconds = 10;
  Timer? _countdownTimer;
  int _secondsRemaining = _maxTimeSeconds;

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    _countdownTimer?.cancel();
    setState(() {
      _selectedDirection = null;
    });
  }

  void _startTimer(VocabularyQuest quest) {
    _countdownTimer?.cancel();
    _secondsRemaining = _maxTimeSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (isAnswered) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
        if (_secondsRemaining <= 3) {
          di.sl<HapticService>().light();
        }
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _shakeCount++;
        });
        _comboStreak = 0;
        di.sl<HapticService>().error();
        submitWrongAnswer(quest: quest, userAnswer: 'TIME_OUT');
      }
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
    _countdownTimer?.cancel();

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

  Widget _buildSpeedArenaBar(Color primaryColor) {
    final isDanger = _secondsRemaining <= 3;
    final activeColor = isDanger ? AppColors.gameIncorrect : primaryColor;

    return Container(
      margin: EdgeInsets.only(top: 4.h, bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: isDanger ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: activeColor.withValues(alpha: isDanger ? 0.4 : 0.22),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: activeColor, size: 15.r),
          SizedBox(width: 4.w),
          Text(
            'SPEED ARENA',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: activeColor,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Icon(Icons.timer_rounded, color: activeColor, size: 14.r),
          SizedBox(width: 4.w),
          Text(
            '${_secondsRemaining}s',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: activeColor,
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 60.w,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: (_secondsRemaining / _maxTimeSeconds).clamp(0.0, 1.0),
                minHeight: 5.h,
                backgroundColor: primaryColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              ),
            ),
          ),
        ],
      ),
    );
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
          _startTimer(quest);
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
                _countdownTimer?.cancel();
                if (isCorr == false) {
                  isAnsweredNotifier.value = false;
                  isCorrectNotifier.value = null;
                  setState(() {
                    _selectedDirection = null;
                  });
                  _startTimer(quest);
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
                            _buildSpeedArenaBar(primaryColor),
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
