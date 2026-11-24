import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/controllers/topic_vocab_controller.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_fusion_timer.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_matrix_grid.dart';

/// High-stakes Mastery Phase evaluation screen for Topic Vocab ("Cluster Fusion").
/// Learners must identify and fuse all topical clusters before the timer runs out.
class TopicVocabScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  final bool isBonusStage;

  const TopicVocabScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.topicVocab,
    this.isBonusStage = false,
  });

  @override
  State<TopicVocabScreen> createState() => _TopicVocabScreenState();
}

class _TopicVocabScreenState extends State<TopicVocabScreen>
    with
        GameScreenMixin<TopicVocabScreen>,
        VocabularyGameScreenMixin<TopicVocabScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  TopicVocabController? _controller;
  VocabularyQuest? _currentQuest;
  Timer? _countdownTimer;
  Timer? _bonusTimer;
  int _bonusSeconds = 0;
  int _totalSeconds = 45;
  int _remainingSeconds = 45;
  bool _isPaused = false;

  @override
  void onGamePaused() {
    super.onGamePaused();
    _isPaused = true;
  }

  @override
  void onGameResumed() {
    super.onGameResumed();
    _isPaused = false;
  }

  int _computeTotalSeconds(VocabularyQuest quest) {
    final count = quest.options?.length ?? 6;
    if (count <= 6) return 45;
    if (count <= 9) return 60;
    return 75;
  }

  @override
  void initState() {
    super.initState();
    final initialBlocState = context.read<VocabularyBloc>().state;
    if (initialBlocState is VocabularyLoaded) {
      lastProcessedIndex = initialBlocState.currentIndex;
      _currentQuest = initialBlocState.currentQuestOrNull;
      if (_currentQuest != null) {
        _initQuestState(_currentQuest!);
      }
    }
    if (di.sl.isRegistered<TtsService>()) {
      unawaited(di.sl<TtsService>().preWarm());
    }
    initVocabularyGame();
  }

  @override
  void onQuestionReset() {
    if (_currentQuest != null) {
      _initQuestState(_currentQuest!, forceReset: true);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bonusTimer?.cancel();
    _controller?.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _remainingSeconds = _totalSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (isAnsweredNotifier.value) {
        timer.cancel();
        return;
      }
      if (_isPaused) return;
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _remainingSeconds = 0;
        });
        timer.cancel();
        _handleTimeExpired();
      }
    });
  }

  void _handleTimeExpired() {
    if (isAnsweredNotifier.value) return;
    hapticService.error();
    _controller?.autoSolve();
    if (_currentQuest != null) {
      submitWrongAnswer(quest: _currentQuest!, userAnswer: 'Time Expired');
    }
  }

  void _initQuestState(VocabularyQuest quest, {bool forceReset = false}) {
    if (!forceReset && _currentQuest?.id == quest.id && _controller != null) {
      return;
    }
    _currentQuest = quest;
    _controller?.dispose();
    _bonusTimer?.cancel();
    _bonusSeconds = 0;
    _totalSeconds = _computeTotalSeconds(quest);
    _remainingSeconds = _totalSeconds;

    final clusters = TopicClusterGroup.parseClusters(quest);
    final initialTiles = quest.options != null && quest.options!.isNotEmpty
        ? List<String>.from(quest.options!)
        : null;

    _controller =
        TopicVocabController(
          targetClusters: clusters,
          targetClusterSize: 3,
          initialTiles: initialTiles,
          hapticService: hapticService,
        )..addListener(() {
          if (mounted) setState(() {});
        });

    _startTimer();
  }

  void _handleFuse() {
    if (isAnsweredNotifier.value || _controller == null) return;

    final fused = _controller!.submitFusion();
    if (fused != null) {
      final combo = _controller!.comboMultiplier;
      soundService.playCorrect(comboStep: combo);
      if (combo >= 2) {
        hapticService.heavy();
      } else {
        hapticService.success();
      }

      _bonusTimer?.cancel();
      setState(() {
        _remainingSeconds = (_remainingSeconds + 10).clamp(1, _totalSeconds);
        _bonusSeconds = 10;
      });
      _bonusTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _bonusSeconds = 0);
      });

      if (_controller!.isComplete) {
        _countdownTimer?.cancel();
        submitCorrectAnswer();
      }
    } else {
      if (_currentQuest != null && _controller!.failedAttempts >= 3) {
        _countdownTimer?.cancel();
        _controller?.autoSolve();
        submitWrongAnswer(quest: _currentQuest!, userAnswer: 'Multiple failed fusions');
      } else {
        soundService.playSoftWrong();
      }
    }
  }

  void _handleContinue(VocabularyLoaded state) {
    if (isCorrectNotifier.value == false &&
        !state.isFinalFailure &&
        state.livesRemaining > 0) {
      isAnsweredNotifier.value = false;
      isCorrectNotifier.value = null;
      context.read<VocabularyBloc>().add(const RetryCurrentQuestion());
      _initQuestState(state.currentQuest, forceReset: true);
    } else {
      dispatchNextQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('topicVocab', level: widget.level);
    final accentColor = theme.primaryColor;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNew = state.currentIndex != lastProcessedIndex;
          final isRetry = !isNew &&
              !state.answerStatus.isAnswered &&
              isAnsweredNotifier.value;
          final isLivesRestored =
              lastLives != null && state.livesRemaining > lastLives!;

          onVocabularyStateChanged(context, state);

          if (isNew || isRetry || isLivesRestored) {
            _currentQuest = state.currentQuestOrNull ?? _currentQuest;
            if (_currentQuest != null) {
              _initQuestState(
                _currentQuest!,
                forceReset: isRetry || isLivesRestored,
              );
            }
          }
        } else if (state is VocabularyGameOver) {
          onVocabularyStateChanged(context, state);
          _countdownTimer?.cancel();
          _bonusTimer?.cancel();
        } else if (state is VocabularyGameComplete) {
          onVocabularyStateChanged(context, state);
          _countdownTimer?.cancel();
          _bonusTimer?.cancel();
        }
      },
      builder: (context, state) {
        if (state is VocabularyError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(),
            ),
            body: GameErrorView(
              message: state.message,
              primaryColor: accentColor,
              onRetry: initVocabularyGame,
              onExit: () => Navigator.of(context).maybePop(),
            ),
          );
        }

        if (state is VocabularyLoaded) {
          _currentQuest = state.currentQuestOrNull ?? _currentQuest;
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuestOrNull
            : _currentQuest;

        if (quest == null &&
            (state is VocabularyLoading || state is VocabularyInitial)) {
          return Scaffold(
            body: SafeArea(
              child: GameShimmerLoading(primaryColor: accentColor),
            ),
          );
        }

        if (quest != null && _controller == null) {
          _initQuestState(quest);
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
          ]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              onPause: onGamePaused,
              onResume: onGameResumed,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure:
                  state is VocabularyLoaded ? state.isFinalFailure : false,
              showConfetti: showConfettiNotifier.value,
              onContinue: () {
                if (state is VocabularyLoaded) {
                  _handleContinue(state);
                } else {
                  dispatchNextQuestion();
                }
              },
              onHint: dispatchHintUsed,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: accentColor)
                  : Column(
                      children: [
                        TopicFusionTimer(
                          remainingSeconds: _remainingSeconds,
                          totalSeconds: _totalSeconds,
                          accentColor: accentColor,
                          bonusSecondsAdded: _bonusSeconds,
                          comboMultiplier: _controller?.comboMultiplier ?? 1,
                        ),
                        SizedBox(height: 12.h),
                        Expanded(
                          child: _controller != null
                              ? TopicMatrixGrid(
                                  controller: _controller!,
                                  accentColor: accentColor,
                                  onFuse: _handleFuse,
                                  isAnswered: isAnsweredNotifier.value,
                                  instruction: quest.instruction,
                                  topicEmoji: quest.topicEmoji,
                                )
                              : const SizedBox.shrink(),
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
