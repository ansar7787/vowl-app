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
  List<String> _dynamicOptions = [];
  String? _selectedWord;
  double _pullForce = 0.0;
  bool _isListening = false;
  bool _isWordPlaced = false;

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

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

    _dynamicOptions = [
      correctWord.toLowerCase(),
      distractors[0],
      distractors[1],
    ];

    _dynamicOptions.shuffle(math.Random(widget.level));
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
    if (_isAnswered || _isWordPlaced) return;
    _hapticService.selection();
    setState(() {
      _selectedWord = word;
      _isListening = true;
    });
  }

  void _onPullEnd() {
    if (_isAnswered || _isWordPlaced) return;
    setState(() {
      _isListening = false;
    });
    if (_pullForce >= 1.0) {
      _hapticService.success();
      _soundService.playClick();
      setState(() {
        _isWordPlaced = true;
      });
    } else {
      setState(() {
        _pullForce = 0.0;
        _selectedWord = null;
      });
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, String expectedWord) {
    if (_isAnswered) return;

    final bool wordIsCorrect =
        _selectedWord?.toLowerCase() == expectedWord.toLowerCase();
    final bool isOverallCorrect = wordIsCorrect && nailedIt;

    setState(() {
      _isAnswered = true;
      _isCorrect = isOverallCorrect;
    });

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
          userAnswer: _selectedWord ?? '[None]',
          correctAnswer: expectedWord,
          level: widget.level,
        );
      }
      
      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
    });
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    if (_isListening && _pullForce < 1.0) {
      Future.delayed(const Duration(milliseconds: 16), () {
        if (mounted && _isListening) {
          setState(() {
            _pullForce = (_pullForce + 0.045).clamp(0.0, 1.0);
            _hapticService.selection();
          });
        }
      });
    }

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _pullForce = 0.0;
              _selectedWord = null;
              _isWordPlaced = false;
              _generateDynamicOptions(
                state.currentQuest.missingWord ?? "drone",
              );
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              } else {
                _isAnswered = false;
              }
            });
          }
          _lastLives = state.livesRemaining;

          if (state.isLetterRevealed && _dynamicOptions.length > 1) {
            final correctWord =
                state.currentQuest.missingWord?.toLowerCase() ?? "";
            if (_dynamicOptions.contains(correctWord)) {
              setState(() {
                _dynamicOptions = [correctWord];
              });
            }
          }
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
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
          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () =>
                context.read<SpeakingBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : CustomScrollView(
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
                                isWordPlaced: _isWordPlaced,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              SpeakMissingWordVortexSentence(
                                text: _isWordPlaced
                                    ? completedSentence
                                    : initialBlankSentence,
                                insertedWord: _isWordPlaced
                                    ? (_selectedWord ?? "")
                                    : "",
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                              ),
                              SizedBox(height: 32.h),
                              if (!_isWordPlaced)
                                SpeakMissingWordMagnetArena(
                                  dynamicOptions: _dynamicOptions,
                                  selectedWord: _selectedWord,
                                  pullForce: _pullForce,
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
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_isWordPlaced && !_isAnswered)
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
        );
      },
    );
  }
}
