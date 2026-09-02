import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking_self_evaluation_controls.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_instruction.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_vortex_sentence.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_magnet_arena.dart';

class SpeakMissingWordScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeakMissingWordScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakMissingWord,
  });

  @override
  State<SpeakMissingWordScreen> createState() => _SpeakMissingWordScreenState();
}

class _SpeakMissingWordScreenState extends State<SpeakMissingWordScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _vortexController;

  int _lastProcessedIndex = -1;
  int? _lastLives;

  // Option states
  final ValueNotifier<List<String>> _dynamicOptions = ValueNotifier([]);
  final ValueNotifier<String?> _selectedWord = ValueNotifier(null);
  final ValueNotifier<double> _pullForce = ValueNotifier(0.0);
  final ValueNotifier<bool> _isListening = ValueNotifier(false);
  final ValueNotifier<bool> _isWordPlaced = ValueNotifier(false);

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vortexController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _vortexController.dispose();
    _dynamicOptions.dispose();
    _selectedWord.dispose();
    _pullForce.dispose();
    _isListening.dispose();
    _isWordPlaced.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  void _generateDynamicOptions(String correctWord) {
    final List<String> distractors = [
      "satellite",
      "reactor",
      "circuit",
      "database",
      "system",
      "portal",
      "shield",
      "drone",
      "module",
    ];

    distractors.remove(correctWord.toLowerCase());
    distractors.shuffle(math.Random(widget.level));

    final newOptions = [
      correctWord.toLowerCase(),
      distractors[0],
      distractors[1],
    ];

    newOptions.shuffle(math.Random(widget.level));
    _dynamicOptions.value = newOptions;
  }

  String _formatBlankSentence(String text, String missingWord) {
    final String cleanText = text;
    final List<String> nouns = [
      missingWord.toLowerCase(),
      "circuit",
      "database",
      "satellite",
      "shield",
      "reactor",
      "module",
      "engine",
      "network",
      "laser",
      "drone",
      "system",
      "portal",
      "archive",
      "data",
    ];

    for (var noun in nouns) {
      final int index = cleanText.toLowerCase().indexOf(noun);
      if (index != -1) {
        return cleanText.replaceRange(
          index,
          index + noun.length,
          " [ ______ ] ",
        );
      }
    }

    return cleanText.replaceAll(missingWord, " [ ______ ] ");
  }

  void _onPullStart(String word) {
    if (_isAnswered.value || _isWordPlaced.value) return;
    _hapticService.selection();
    _selectedWord.value = word;
    _isListening.value = true;
  }

  void _onPullEnd() {
    if (_isAnswered.value || _isWordPlaced.value) return;
    _isListening.value = false;
    if (_pullForce.value >= 1.0) {
      _hapticService.success();
      _soundService.playClick();
      _isWordPlaced.value = true;
    } else {
      _pullForce.value = 0.0;
      _selectedWord.value = null;
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, String expectedWord) {
    if (_isAnswered.value) return;

    final bool wordIsCorrect =
        _selectedWord.value?.toLowerCase() == expectedWord.toLowerCase();
    final bool isOverallCorrect = wordIsCorrect && nailedIt;

    _isAnswered.value = true;
    _isCorrect.value = isOverallCorrect;

    if (isOverallCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: expectedWord,
          userAnswer: _selectedWord.value ?? '[None]',
          correctAnswer: expectedWord,
          level: widget.level,
        );
      }
      
      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    _isAnswered.value = true;
    _isCorrect.value = true;
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    if (_isListening.value && _pullForce.value < 1.0) {
      Future.delayed(const Duration(milliseconds: 16), () {
        if (mounted && _isListening.value) {
          _pullForce.value = (_pullForce.value + 0.045).clamp(0.0, 1.0);
          _hapticService.selection();
        }
      });
    }

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isListening.value = false;
            _pullForce.value = 0.0;
            _selectedWord.value = null;
            _isWordPlaced.value = false;
            _generateDynamicOptions(
              state.currentQuest.missingWord ?? "drone",
            );
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            if (state.isFinalFailure || state.livesRemaining <= 0) {
              _isAnswered.value = true;
            } else {
              _isAnswered.value = false;
            }
          }
          _lastLives = state.livesRemaining;

          if (state.isLetterRevealed && _dynamicOptions.value.length > 1) {
            final correctWord =
                state.currentQuest.missingWord?.toLowerCase() ?? "";
            if (_dynamicOptions.value.contains(correctWord)) {
              _dynamicOptions.value = [correctWord];
            }
          }
        }
        if (state is SpeakingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr('speaking_games.verbal_vortex', fallback: 'VERBAL VORTEX DRIVER!'),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        final String rawSentence =
            quest?.textToSpeak ?? "The robot operates the system safely.";
        final String missingWord = quest?.missingWord ?? "robot";

        final String initialBlankSentence = _formatBlankSentence(
          rawSentence,
          missingWord,
        );
        final String completedSentence = rawSentence;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _dynamicOptions, _selectedWord, _pullForce, _isWordPlaced, _isListening]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,
            onContinue: () =>
                context.read<SpeakingBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : Stack(
                    children: [
                      RawScrollbar(
                        controller: _scrollController,
                        thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                        radius: Radius.circular(8.r),
                        thickness: 4.w,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SpeakMissingWordInstruction(
                                primaryColor: theme.primaryColor,
                                isWordPlaced: _isWordPlaced.value,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              SpeakMissingWordVortexSentence(
                                text: _isWordPlaced.value
                                    ? completedSentence
                                    : initialBlankSentence,
                                insertedWord: _isWordPlaced.value
                                    ? (_selectedWord.value ?? "")
                                    : "",
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                              ),
                              SizedBox(height: 32.h),
                              if (!_isWordPlaced.value)
                                SpeakMissingWordMagnetArena(
                                  dynamicOptions: _dynamicOptions.value,
                                  selectedWord: _selectedWord.value,
                                  pullForce: _pullForce.value,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  vortexController: _vortexController,
                                  onPullStart: _onPullStart,
                                  onPullEnd: _onPullEnd,
                                ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_isWordPlaced.value && !_isAnswered.value)
                                SpeakingSelfEvaluationControls(
                                  expectedText: completedSentence,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(
                                        true,
                                        missingWord,
                                      ),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(
                                        false,
                                        missingWord,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
