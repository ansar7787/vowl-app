import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_grid_builder.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_mastery_controller.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_grid_context_header.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_streak_timer_bar.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_word_grid_board.dart';

/// Mastery Phase for Synonym Search ("Synonym Word-Grid Blitz").
///
/// Integrates with [VocabularyBloc], [VocabularyBaseLayout], and [GameScreenMixin]
/// to deliver 3 timed connected-letter word grids per level with drag/tap tracing,
/// CEFR-scaled countdowns, decoy traps, and full educational feedback.
class SynonymSearchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SynonymSearchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.synonymSearch,
  });

  @override
  State<SynonymSearchScreen> createState() => _SynonymSearchScreenState();
}

class _SynonymSearchScreenState extends State<SynonymSearchScreen>
    with
        GameScreenMixin<SynonymSearchScreen>,
        VocabularyGameScreenMixin<SynonymSearchScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  late final SynonymMasteryController _controller;
  final ValueNotifier<int> _roundResetNonce = ValueNotifier<int>(0);
  String? _lastLoadedQuestId;
  bool _pendingRoundReset = false;

  @override
  void initState() {
    super.initState();
    timerKey = GlobalKey<SpeedChallengeTimerState>();
    initGameLifecycle();
    try {
      TtsService().preWarm();
    } catch (_) {}

    _controller = SynonymMasteryController(
      hapticService: _tryHaptic(),
      onCorrectFound: _handleCorrectFound,
      onWrongAttempt: _handleWrongAttempt,
    );

    final initialState = context.read<VocabularyBloc>().state;
    if (initialState is VocabularyLoaded) {
      final quest = initialState.currentQuestOrNull;
      if (quest != null) {
        _lastLoadedQuestId = quest.id;
        _controller.loadQuest(quest, level: widget.level, forceReset: true);
        if (initialState.hintUsed) {
          _controller.activateHint();
        }
        lastProcessedIndex = initialState.currentIndex;
        lastLives = initialState.livesRemaining;
        isAnsweredNotifier.value = initialState.answerStatus.isAnswered;
        isCorrectNotifier.value = initialState.answerStatus.asBoolOrNull;
      }
    } else {
      initVocabularyGame();
    }
  }

  HapticService? _tryHaptic() {
    try {
      return di.sl<HapticService>();
    } catch (_) {
      return null;
    }
  }

  void _stopAudioSafely() {
    try {
      TtsSpeakerButtonWidget.stopAll();
      TtsService().stop();
    } catch (_) {}
  }

  void _handleCorrectFound() {
    if (!mounted) return;
    timerKey?.currentState?.pause();
    _stopAudioSafely();
    submitCorrectAnswer();
  }

  void _handleWrongAttempt(String? attemptedWord) {
    if (!mounted) return;
    timerKey?.currentState?.pause();
    _stopAudioSafely();
    final state = context.read<VocabularyBloc>().state;
    if (state is VocabularyLoaded && state.currentQuestOrNull != null) {
      submitWrongAnswer(
        quest: state.currentQuestOrNull!,
        userAnswer: attemptedWord,
      );
    }
  }

  @override
  void onQuestionReset() {
    if (!mounted) return;
    final state = context.read<VocabularyBloc>().state;
    if (state is VocabularyLoaded && state.currentQuestOrNull != null) {
      final quest = state.currentQuestOrNull!;
      final isSameQuestRetry = _lastLoadedQuestId == quest.id;
      _lastLoadedQuestId = quest.id;
      _controller.loadQuest(quest, level: widget.level, forceReset: true);
      if (isSameQuestRetry) {
        _controller.resetForRetryOrNext(keepComboOnNext: false);
      }
    }
  }

  @override
  void dispose() {
    _stopAudioSafely();
    _roundResetNonce.dispose();
    _controller.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  bool _handleListenWhen(VocabularyState prev, VocabularyState curr) {
    if (curr is VocabularyLoading ||
        curr is VocabularyGameOver ||
        curr is VocabularyInitial) {
      _pendingRoundReset = true;
    }
    return vocabularyListenWhen(prev, curr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.of(
      context,
      widget.gameType.name,
      level: widget.level,
    );

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: _handleListenWhen,
      listener: (context, state) {
        onVocabularyStateChanged(context, state);

        if (state is VocabularyLoaded) {
          final quest = state.currentQuestOrNull;
          if (quest != null) {
            final isNewQuest = _lastLoadedQuestId != quest.id;
            final shouldForceReset = _pendingRoundReset || isNewQuest;
            _lastLoadedQuestId = quest.id;
            _controller.loadQuest(
              quest,
              level: widget.level,
              forceReset: shouldForceReset,
            );
            if (_pendingRoundReset) {
              _pendingRoundReset = false;
              if (state.currentIndex == 0 && !state.answerStatus.isAnswered) {
                _controller.resetForRetryOrNext(keepComboOnNext: false);
                timerKey = GlobalKey<SpeedChallengeTimerState>();
                _roundResetNonce.value = _roundResetNonce.value + 1;
              }
            }
          }
          if (state.hintUsed) {
            _controller.activateHint();
          }
          if (state.answerStatus.isAnswered) {
            timerKey?.currentState?.pause();
          }
        } else if (state is VocabularyGameOver ||
            state is VocabularyGameComplete) {
          timerKey?.currentState?.pause();
          _stopAudioSafely();
        }
      },
      builder: (context, state) {
        final isLoaded = state is VocabularyLoaded;
        final VocabularyQuest? quest = isLoaded
            ? state.currentQuestOrNull
            : null;
        final bool isFinalFailure = isLoaded ? state.isFinalFailure : false;

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
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              hasStage2: false,
              useScrolling: true,
              customHintText: quest?.hint,
              onContinue: () {
                _stopAudioSafely();
                dispatchNextQuestion();
              },
              onHint: _controller.activateHint,
              onPause: onGamePaused,
              onResume: onGameResumed,
              child: quest == null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: GameShimmerLoading(
                          primaryColor: theme.primaryColor,
                        ),
                      ),
                    )
                  : _buildGameplayBody(
                      quest: quest,
                      primaryColor: theme.primaryColor,
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildGameplayBody({
    required VocabularyQuest quest,
    required Color primaryColor,
  }) {
    final fallbackGrid = SynonymGridBuilder.build(
      questId: quest.id,
      correctAnswer: quest.correctAnswer ?? quest.synonym ?? 'LARGE',
      options: quest.options ?? const [],
    );

    return ListenableBuilder(
      listenable: Listenable.merge([
        _roundResetNonce,
        _controller.grid,
        _controller.activePath,
        _controller.comboStreak,
        _controller.isHintActive,
        _controller.shakeCount,
        _controller.showSuccessFlash,
        _controller.subtleStatusMessage,
      ]),
      builder: (context, _) {
        final activeGrid = _controller.grid.value ?? fallbackGrid;
        final path = _controller.activePath.value;
        final spelled = activeGrid.spellPath(path);
        final durationSeconds = _controller.timerDurationFor(
          quest,
          widget.level,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SynonymStreakTimerBar(
              timerKey: timerKey!,
              durationSeconds: durationSeconds,
              comboStreak: _controller.comboStreak.value,
              primaryColor: primaryColor,
              autoStart: !isAnsweredNotifier.value,
              onTimeUp: _controller.handleTimerExpired,
            ),
            SizedBox(height: 10.h),
            SynonymGridContextHeader(
              quest: quest,
              level: widget.level,
              normalizedTarget: activeGrid.normalizedTarget,
              currentSpelledWord: spelled,
              isHintActive: _controller.isHintActive.value,
              primaryColor: primaryColor,
            ),
            SizedBox(height: 12.h),
            SynonymWordGridBoard(
              grid: activeGrid,
              activePath: path,
              isHintActive: _controller.isHintActive.value,
              shakeCount: _controller.shakeCount.value,
              showSuccessFlash: _controller.showSuccessFlash.value,
              subtleStatusMessage: _controller.subtleStatusMessage.value,
              primaryColor: primaryColor,
              onStartDrag: _controller.startDragAt,
              onExtendDrag: _controller.extendDragTo,
              onEndDrag: _controller.endDrag,
              onTapCell: _controller.tapCell,
              onBackspace: _controller.backspace,
              onClear: _controller.clearPath,
            ),
            SizedBox(height: 12.h),
          ],
        );
      },
    );
  }
}
