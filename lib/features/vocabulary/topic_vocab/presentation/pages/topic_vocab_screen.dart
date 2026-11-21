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
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_word_peek_sheet.dart';

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
  int _remainingSeconds = 30;
  static const int _totalSeconds = 30;

  @override
  void initState() {
    super.initState();
    if (di.sl.isRegistered<TtsService>()) {
      unawaited(di.sl<TtsService>().preWarm());
    }
    initVocabularyGame();
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

    final clusters = _parseClusters(quest);
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

  List<String> _extractCollocations(List<String> words, VocabularyQuest quest) {
    final result = <String>[];
    for (final coll in quest.collocations ?? <String>[]) {
      if (words.any((w) => coll.toLowerCase().contains(w.toLowerCase()))) {
        result.add(coll);
      }
    }
    if (result.isEmpty && quest.relatedWords != null) {
      for (final rw in quest.relatedWords!) {
        if (words.any((w) => rw.toLowerCase().contains(w.toLowerCase()))) {
          final clean = rw.contains(':') ? rw.split(':')[0].trim() : rw.trim();
          if (clean.contains(' ')) result.add(clean);
        }
      }
    }
    return result;
  }

  List<TopicClusterGroup> _parseClusters(VocabularyQuest quest) {
    final Map<String, List<String>> bucketMap = {};
    if (quest.correctAnswer != null && quest.correctAnswer!.contains(':')) {
      for (final p in quest.correctAnswer!.split(',').map((s) => s.trim())) {
        final parts = p.split(':');
        if (parts.length == 2) {
          bucketMap.putIfAbsent(parts[0].trim(), () => []).add(parts[1].trim());
        }
      }
    }

    final emoji = quest.topicEmoji ?? '';

    if (bucketMap.isNotEmpty) {
      return bucketMap.entries.map((e) {
        return TopicClusterGroup(
          categoryName: e.key,
          emoji: emoji,
          words: e.value,
          explanation: quest.explanation,
          collocations: _extractCollocations(e.value, quest),
        );
      }).toList();
    }

    final buckets = quest.topicBuckets ?? <String>[];
    final options = quest.options ?? <String>[];
    final bucketCount = buckets.isNotEmpty ? buckets.length : 1;
    final perBucket = options.isNotEmpty ? (options.length / bucketCount).ceil() : 0;

    final result = <TopicClusterGroup>[];
    for (var i = 0; i < buckets.length; i++) {
      final start = i * perBucket;
      final end = (start + perBucket).clamp(0, options.length);
      final words = (start < options.length) ? options.sublist(start, end) : <String>[];
      result.add(
        TopicClusterGroup(
          categoryName: buckets[i],
          emoji: emoji,
          words: words,
          explanation: quest.explanation,
          collocations: _extractCollocations(words, quest),
        ),
      );
    }
    return result;
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
        _remainingSeconds = (_remainingSeconds + 5).clamp(1, _totalSeconds);
        _bonusSeconds = 5;
      });
      _bonusTimer = Timer(const Duration(milliseconds: 1200), () {
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

  void _handleTileLongPress(String word) async {
    if (_currentQuest == null) return;
    String? matchedDefinition;
    String? matchedCategory;

    final related = _currentQuest!.relatedWords ?? [];
    for (final rw in related) {
      final lower = rw.toLowerCase();
      if (lower.startsWith('${word.toLowerCase()}:') ||
          lower.startsWith('${word.toLowerCase()} -')) {
        final parts = rw.split(RegExp(r'[:\-]'));
        if (parts.length > 1) {
          matchedDefinition = parts.sublist(1).join(':').trim();
        }
        break;
      }
    }

    if (_controller != null) {
      for (final c in _controller!.targetClusters) {
        if (c.words.contains(word)) {
          matchedCategory = c.categoryName;
          matchedDefinition ??= c.explanation;
          break;
        }
      }
    }

    final theme = LevelThemeHelper.getTheme('topicVocab', level: widget.level);
    final wasTimerRunning = _countdownTimer?.isActive ?? false;
    _countdownTimer?.cancel();

    await TopicWordPeekSheet.show(
      context,
      word: word,
      definition: matchedDefinition ?? _currentQuest!.explanation,
      categoryHint: matchedCategory,
      accentColor: theme.primaryColor,
    );

    if (mounted && wasTimerRunning && isAnsweredNotifier.value == false && _remainingSeconds > 0) {
      _startTimer();
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
        onVocabularyStateChanged(context, state);
        if (state is VocabularyLoaded) {
          _initQuestState(state.currentQuest);
        }
      },
      builder: (context, state) {
        if (state is VocabularyLoading || state is VocabularyInitial) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    ShimmerLoading.rounded(height: 50.h, width: double.infinity, borderRadius: 12),
                    SizedBox(height: 16.h),
                    ShimmerLoading.rounded(height: 250.h, width: double.infinity, borderRadius: 16),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is VocabularyError) {
          return Scaffold(
            body: GameErrorView(
              message: state.message,
              onRetry: initVocabularyGame,
            ),
          );
        }

        if (state is VocabularyLoaded) {
          if (_controller == null) {
            _initQuestState(state.currentQuest);
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
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                isFinalFailure: state.isFinalFailure,
                showConfetti: showConfettiNotifier.value,
                onContinue: () => _handleContinue(state),
                onHint: dispatchHintUsed,
                child: Column(
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
                              instruction: _currentQuest?.instruction,
                              topicEmoji: _currentQuest?.topicEmoji,
                              onTileLongPress: _handleTileLongPress,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}
