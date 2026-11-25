import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/controllers/prefix_suffix_controller.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_combo_hud.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_precision_slicer.dart';

/// Interactive Prefix & Suffix Mastery Game Screen: "Morpheme Precision Slicer".
///
/// Features:
/// - 5-second rapid reaction countdown timer with combo multiplier HUD.
/// - Laser seam slicing mechanics across morpheme boundaries.
/// - Integrated with [VocabularyBaseLayout] (single-turn arcade mode: hasStage2: false).
class PrefixSuffixScreen extends StatefulWidget {
  /// The active curriculum difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Whether this session is running as a mastery bonus stage.
  final bool isBonusStage;

  /// Whether the arcade countdown timer is active.
  final bool enableTimer;

  const PrefixSuffixScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prefixSuffix,
    this.isBonusStage = false,
    this.enableTimer = true,
  });

  @override
  State<PrefixSuffixScreen> createState() => _PrefixSuffixScreenState();
}

class _PrefixSuffixScreenState extends State<PrefixSuffixScreen>
    with
        TickerProviderStateMixin,
        GameScreenMixin<PrefixSuffixScreen>,
        VocabularyGameScreenMixin<PrefixSuffixScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'Level Complete!';

  late final PrefixSuffixController _controller;
  VocabularyQuest? _currentQuest;
  int _lastProcessedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = PrefixSuffixController();
    if (di.sl.isRegistered<TtsService>()) {
      unawaited(di.sl<TtsService>().preWarm(locale: 'en-US'));
    }
    final initialBlocState = context.read<VocabularyBloc>().state;
    if (initialBlocState is VocabularyLoaded) {
      final q = initialBlocState.currentQuestOrNull;
      if (q != null) {
        _lastProcessedIndex = initialBlocState.currentIndex;
        _currentQuest = q;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onQuestLoaded(q);
        });
      }
    }
    initVocabularyGame();
  }

  @override
  void onQuestionReset() {
    isAnsweredNotifier.value = false;
    isCorrectNotifier.value = null;
    _controller.resetForNextQuest();
    if (_currentQuest != null) {
      _startTimer(_currentQuest!);
    }
  }

  @override
  void dispose() {
    TtsSpeakerButtonWidget.stopAll();
    _controller.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void onGamePaused() {
    super.onGamePaused();
    TtsSpeakerButtonWidget.stopAll();
    _controller.pauseMasteryTimer();
  }

  @override
  void onGameResumed() {
    super.onGameResumed();
    _controller.resumeMasteryTimer();
  }

  void _startTimer(VocabularyQuest quest) {
    if (!widget.enableTimer) return;
    _controller.startMasteryTimer(
      durationSeconds: 10,
      onExpired: () {
        if (!isAnsweredNotifier.value && mounted) {
          _controller.evaluateSlice(cutIndex: -1, correctCutIndex: 0);
          if (di.sl.isRegistered<SoundService>()) {
            di.sl<SoundService>().playWrong();
          }
          if (di.sl.isRegistered<HapticService>()) {
            di.sl<HapticService>().error();
          }
          submitWrongAnswer(quest: quest, userAnswer: 'timeout');
        }
      },
    );
  }

  void _onQuestLoaded(VocabularyQuest quest) {
    TtsSpeakerButtonWidget.stopAll();
    _currentQuest = quest;
    _controller.resetForNextQuest();
    _startTimer(quest);
  }

  int _calculateCorrectCutIndex(VocabularyQuest quest) {
    if (quest.instruction.toUpperCase().contains('UNBREAKABLE') ||
        quest.instruction.toUpperCase().contains('IMPOSTER') ||
        quest.correctAnswer?.toUpperCase().trim() == 'NONE' ||
        quest.correctAnswer?.toUpperCase().trim() == '0') {
      return 0;
    }

    final word = quest.word ?? '';
    final prefix = quest.prefix?.replaceAll('-', '').trim() ?? '';
    if (prefix.isNotEmpty &&
        word.toUpperCase().startsWith(prefix.toUpperCase())) {
      return prefix.length;
    }

    final suffix = quest.suffix?.replaceAll('-', '').trim() ?? '';
    if (suffix.isNotEmpty &&
        word.toUpperCase().endsWith(suffix.toUpperCase())) {
      return word.length - suffix.length;
    }

    final correctAnswer = quest.correctAnswer?.replaceAll('-', '').trim() ?? '';
    if (correctAnswer.isNotEmpty) {
      if (word.toUpperCase().startsWith(correctAnswer.toUpperCase())) {
        return correctAnswer.length;
      } else if (word.toUpperCase().endsWith(correctAnswer.toUpperCase())) {
        return word.length - correctAnswer.length;
      }
    }

    return (word.length ~/ 2).clamp(1, (word.length - 1).clamp(1, 99));
  }

  int? _calculateSecondaryCutIndex(VocabularyQuest quest) {
    final word = quest.word ?? '';
    final prefix = quest.prefix?.replaceAll('-', '').trim() ?? '';
    final suffix = quest.suffix?.replaceAll('-', '').trim() ?? '';
    if (prefix.isNotEmpty &&
        suffix.isNotEmpty &&
        word.toUpperCase().startsWith(prefix.toUpperCase()) &&
        word.toUpperCase().endsWith(suffix.toUpperCase()) &&
        word.length > prefix.length + suffix.length) {
      return word.length - suffix.length;
    }
    return null;
  }

  void _handleSlice(int severedSeam, VocabularyQuest quest) {
    if (isAnsweredNotifier.value) return;

    final correctSeam = _calculateCorrectCutIndex(quest);
    final secondarySeam = _calculateSecondaryCutIndex(quest);
    final isCorrect = _controller.evaluateSlice(
      cutIndex: severedSeam,
      correctCutIndex: correctSeam,
      secondaryCutIndex: secondarySeam,
    );

    if (isCorrect) {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect();
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
      submitCorrectAnswer();
    } else {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playWrong();
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
      submitWrongAnswer(quest: quest, userAnswer: 'seam_$severedSeam');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: (context, state) {
        onVocabularyStateChanged(context, state);
        if (state is VocabularyGameOver || state is VocabularyGameComplete) {
          _controller.stopMasteryTimer();
        } else if (state is VocabularyLoaded) {
          final isNew = state.currentIndex != _lastProcessedIndex;
          final isRetry =
              !isNew &&
              !state.answerStatus.isAnswered &&
              isAnsweredNotifier.value;

          if (isNew || isRetry) {
            _lastProcessedIndex = state.currentIndex;
            _currentQuest = state.currentQuestOrNull ?? _currentQuest;
            isAnsweredNotifier.value = false;
            isCorrectNotifier.value = null;
            if (_currentQuest != null) {
              _onQuestLoaded(_currentQuest!);
            }
          }
        }
      },
      builder: (context, state) {
        if (state is VocabularyLoaded) {
          _currentQuest = state.currentQuestOrNull ?? _currentQuest;
        }

        final quest =
            (state is VocabularyLoaded ? state.currentQuestOrNull : null) ??
            _currentQuest;

        if (quest == null) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.slate900
                : const Color(0xFFF8FAFC),
            body: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ShimmerLoading.rounded(
                  width: double.infinity,
                  height: 380.h,
                  borderRadius: 20,
                ),
              ),
            ),
          );
        }

        if (state is VocabularyLoaded &&
            state.currentIndex != _lastProcessedIndex) {
          _lastProcessedIndex = state.currentIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _onQuestLoaded(quest);
            }
          });
        }

        final word = quest.word ?? 'PREVIEW';
        final correctCutIndex = _calculateCorrectCutIndex(quest);

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _controller,
          ]),
          builder: (context, _) {
            final isAns = isAnsweredNotifier.value;
            final isCorr = isCorrectNotifier.value;
            final confetti = showConfettiNotifier.value;

            return VocabularyBaseLayout(
              gameType: gameType,
              level: level,
              onPause: onGamePaused,
              onResume: onGameResumed,
              isAnswered: isAns,
              isCorrect: isCorr,
              showConfetti: confetti,
              onContinue: () {
                TtsSpeakerButtonWidget.stopAll();
                final currentState = context.read<VocabularyBloc>().state;
                final isFinal =
                    currentState is VocabularyLoaded &&
                    (currentState.isFinalFailure ||
                        currentState.livesRemaining <= 0);

                if (!isFinal && isCorr == false) {
                  isAnsweredNotifier.value = false;
                  isCorrectNotifier.value = null;
                  _controller.resetForNextQuest();
                  if (_currentQuest != null) {
                    _startTimer(_currentQuest!);
                  }
                } else {
                  context.read<VocabularyBloc>().add(const NextQuestion());
                }
              },
              onHint: () {
                dispatchHintUsed();
                if (di.sl.isRegistered<TtsService>()) {
                  final w = quest.word ?? '';
                  if (w.isNotEmpty) di.sl<TtsService>().speak(w);
                }
              },
              hasStage2: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  children: [
                    // Urgency Combo HUD
                    PrefixSuffixComboHud(
                      timeFraction: _controller.timeFraction,
                      secondsRemaining: _controller.secondsRemaining,
                      comboMultiplier: _controller.comboMultiplier,
                      currentStreak: _controller.streak,
                    ),
                    SizedBox(height: 16.h),

                    // Instruction Prompt
                    Text(
                      quest.instruction,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Precision Slicer Board
                    PrefixSuffixPrecisionSlicer(
                      word: word,
                      correctCutIndex: correctCutIndex,
                      secondaryCutIndex: _calculateSecondaryCutIndex(quest),
                      isSliced: _controller.isSliced,
                      isWrongCut: _controller.isWrongCut,
                      isAnswered: isAns,
                      onSlice: (seam) => _handleSlice(seam, quest),
                    ),
                    SizedBox(height: 16.h),
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
