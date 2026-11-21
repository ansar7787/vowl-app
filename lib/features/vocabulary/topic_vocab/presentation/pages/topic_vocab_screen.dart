import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
  int _remainingSeconds = 30;
  static const int _totalSeconds = 30;

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
    if (_currentQuest != null) {
      submitWrongAnswer(quest: _currentQuest!, userAnswer: 'Time Expired');
    }
  }

  void _initQuestState(VocabularyQuest quest) {
    if (_currentQuest?.id == quest.id && _controller != null) return;
    _currentQuest = quest;
    _controller?.dispose();

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

  List<TopicClusterGroup> _parseClusters(VocabularyQuest quest) {
    final Map<String, List<String>> bucketMap = {};

    if (quest.correctAnswer != null && quest.correctAnswer!.contains(':')) {
      final pairs = quest.correctAnswer!.split(',').map((s) => s.trim());
      for (final p in pairs) {
        final parts = p.split(':');
        if (parts.length == 2) {
          final bucket = parts[0].trim();
          final word = parts[1].trim();
          bucketMap.putIfAbsent(bucket, () => []).add(word);
        }
      }
    }

    if (bucketMap.isNotEmpty) {
      return bucketMap.entries.map((e) {
        return TopicClusterGroup(
          categoryName: e.key,
          emoji: quest.topicEmoji ?? '🏷️',
          words: e.value,
          explanation: quest.explanation,
        );
      }).toList();
    }

    final buckets = quest.topicBuckets ?? ['Domain Alpha', 'Domain Beta'];
    final options =
        quest.options ??
        ['Word A', 'Word B', 'Word C', 'Word D', 'Word E', 'Word F'];
    final half = (options.length / (buckets.isNotEmpty ? buckets.length : 2))
        .ceil();

    return [
      TopicClusterGroup(
        categoryName: buckets.isNotEmpty ? buckets[0] : 'Domain Alpha',
        emoji: quest.topicEmoji ?? '🔥',
        words: options.take(half).toList(),
        explanation: quest.explanation,
      ),
      TopicClusterGroup(
        categoryName: buckets.length > 1 ? buckets[1] : 'Domain Beta',
        emoji: quest.topicEmoji ?? '❄️',
        words: options.skip(half).toList(),
        explanation: quest.explanation,
      ),
    ];
  }

  void _handleFuse() {
    if (isAnsweredNotifier.value || _controller == null) return;

    final fused = _controller!.submitFusion();
    if (fused != null) {
      if (_controller!.isComplete) {
        _countdownTimer?.cancel();
        submitCorrectAnswer();
      }
    } else {
      if (_currentQuest != null && _controller!.failedAttempts >= 3) {
        _countdownTimer?.cancel();
        submitWrongAnswer(
          quest: _currentQuest!,
          userAnswer: 'Multiple failed fusions',
        );
      }
    }
  }

  void _handleTileLongPress(String word) {
    if (_currentQuest == null) return;
    String? matchedDefinition;
    String? matchedCategory;

    final related = _currentQuest!.relatedWords ?? [];
    for (final rw in related) {
      if (rw.toLowerCase().startsWith('${word.toLowerCase()}:') ||
          rw.toLowerCase().startsWith('${word.toLowerCase()} -')) {
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
    TopicWordPeekSheet.show(
      context,
      word: word,
      definition: matchedDefinition ?? _currentQuest!.explanation,
      categoryHint: matchedCategory,
      accentColor: theme.primaryColor,
    );
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
                    ShimmerLoading.rounded(
                      height: 50.h,
                      width: double.infinity,
                      borderRadius: 12,
                    ),
                    SizedBox(height: 16.h),
                    ShimmerLoading.rounded(
                      height: 250.h,
                      width: double.infinity,
                      borderRadius: 16,
                    ),
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

          return ValueListenableBuilder<bool>(
            valueListenable: isAnsweredNotifier,
            builder: (context, isAnswered, _) {
              return ValueListenableBuilder<bool?>(
                valueListenable: isCorrectNotifier,
                builder: (context, isCorrect, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: showConfettiNotifier,
                    builder: (context, showConfetti, _) {
                      return VocabularyBaseLayout(
                        gameType: widget.gameType,
                        level: widget.level,
                        isAnswered: isAnswered,
                        isCorrect: isCorrect,
                        showConfetti: showConfetti,
                        onContinue: dispatchNextQuestion,
                        onHint: dispatchHintUsed,
                        child: Column(
                          children: [
                            TopicFusionTimer(
                              remainingSeconds: _remainingSeconds,
                              totalSeconds: _totalSeconds,
                              accentColor: accentColor,
                            ),
                            SizedBox(height: 12.h),
                            Expanded(
                              child: _controller != null
                                  ? TopicMatrixGrid(
                                      controller: _controller!,
                                      accentColor: accentColor,
                                      onFuse: _handleFuse,
                                      isAnswered: isAnswered,
                                      onTileLongPress: _handleTileLongPress,
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
            },
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}
