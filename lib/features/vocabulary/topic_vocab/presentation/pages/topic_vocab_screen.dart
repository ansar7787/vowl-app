import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

// Extracted Optimized Widgets
import '../widgets/topic_machine_head.dart';
import '../widgets/topic_containment_bin.dart';
import '../widgets/topic_batch_counter.dart';
import '../widgets/topic_draggable_core.dart';
import '../controllers/topic_vocab_controller.dart';

class TopicVocabScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TopicVocabScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.topicVocab,
  });

  @override
  State<TopicVocabScreen> createState() => _TopicVocabScreenState();
}

class _TopicVocabScreenState extends State<TopicVocabScreen> {
  late final TopicVocabController _controller;
  VocabularyQuest? _lastQuest;
  int? _lastProcessedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = TopicVocabController(
      hapticService: di.sl<HapticService>(),
      soundService: di.sl<SoundService>(),
      onSubmitAnswer: (nailedIt) {
        context.read<VocabularyBloc>().add(SubmitAnswer(nailedIt));
      },
    );
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry =
              !state.answerStatus.isAnswered && _controller.isAnswered;

          if (isNewQuestion || isRetry) {
            _lastQuest = state.currentQuest;
            _lastProcessedIndex = state.currentIndex;
            _controller.reset(state.currentQuest);
          }
        }
        if (state is VocabularyGameComplete) {
          _controller.completeGame();
          if (!context.mounted) return;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'WORD SORTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                _lastQuest == null &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final options = _controller.shuffledOptions.isNotEmpty
                ? _controller.shuffledOptions
                : (quest?.options ?? []);
            final buckets = quest?.topicBuckets ?? ["A", "B"];
            final currentWord = _controller.currentWordIndex < options.length
                ? options[_controller.currentWordIndex]
                : "";
            final correctAnswer = quest?.correctAnswer ?? "";

            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _controller.isAnswered,
              isCorrect: _controller.isCorrect,
              showConfetti: _controller.showConfetti,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(NextQuestion()),
              useScrolling: false,
              customHintText: _controller.currentHint,
              onHint: () {
                _controller.activateHint();
              },
              disablePadding: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use true screen constraints if available, otherwise fallback
                  final maxHeight = constraints.maxHeight == double.infinity
                      ? 500.h
                      : constraints.maxHeight;
                  final maxWidth = constraints.maxWidth == double.infinity
                      ? MediaQuery.of(context).size.width
                      : constraints.maxWidth;
                  final isCompact = maxHeight < 580.h;

                  // Define relative positions as percentages of the actual available height or absolute sizes
                  final counterTop = isCompact ? 15.h : maxHeight * 0.05;
                  final machineTop = isCompact ? 65.h : maxHeight * 0.18;

                  // Word is positioned relative to bottom to work nicely with flicking physics
                  final wordBottom = isCompact ? 145.h : maxHeight * 0.42;
                  final flyingWordBottom = isCompact ? 145.h : maxHeight * 0.42;
                  final binBottom = isCompact ? 10.h : maxHeight * 0.04;

                  return SizedBox(
                    height: maxHeight,
                    width: maxWidth,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // 1. BATCH PROGRESS
                        Positioned(
                          top: counterTop,
                          child: RepaintBoundary(
                            child: TopicBatchCounter(
                              count: _controller.userChoices.length,
                              total: options.length,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),

                        // 3. EMISSION MACHINE
                        Positioned(
                          top: machineTop,
                          child: RepaintBoundary(
                            child: isCompact
                                ? SizedBox(
                                    height: 75.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: TopicMachineHead(
                                        primaryColor: theme.primaryColor,
                                        emoji: quest?.topicEmoji ?? "📦",
                                      ),
                                    ),
                                  )
                                : TopicMachineHead(
                                    primaryColor: theme.primaryColor,
                                    emoji: quest?.topicEmoji ?? "📦",
                                  ),
                          ),
                        ),

                        // Containment Bins
                        Positioned(
                          bottom: binBottom,
                          left:
                              8.w, // Added premium visual margin from the edge
                          child: RepaintBoundary(
                            child: isCompact
                                ? SizedBox(
                                    width: 110.w,
                                    height: 140.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: TopicContainmentBin(
                                        index: 0,
                                        label: buckets[0],
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        correctAnswer: correctAnswer,
                                        currentWord: currentWord,
                                        words: _controller.wordsInBins[0] ?? [],
                                        isHintActive: _controller.isHintActive,
                                      ),
                                    ),
                                  )
                                : TopicContainmentBin(
                                    index: 0,
                                    label: buckets[0],
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    correctAnswer: correctAnswer,
                                    currentWord: currentWord,
                                    words: _controller.wordsInBins[0] ?? [],
                                    isHintActive: _controller.isHintActive,
                                  ),
                          ),
                        ),
                        if (buckets.length > 1)
                          Positioned(
                            bottom: binBottom,
                            right: 8.w,
                            child: RepaintBoundary(
                              child: isCompact
                                  ? SizedBox(
                                      width: 110.w,
                                      height: 140.h,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: TopicContainmentBin(
                                          index: 1,
                                          label: buckets[1],
                                          color: theme.primaryColor,
                                          isDark: isDark,
                                          correctAnswer: correctAnswer,
                                          currentWord: currentWord,
                                          words:
                                              _controller.wordsInBins[1] ?? [],
                                          isHintActive:
                                              _controller.isHintActive,
                                        ),
                                      ),
                                    )
                                  : TopicContainmentBin(
                                      index: 1,
                                      label: buckets[1],
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      correctAnswer: correctAnswer,
                                      currentWord: currentWord,
                                      words: _controller.wordsInBins[1] ?? [],
                                      isHintActive: _controller.isHintActive,
                                    ),
                            ),
                          ),
                        if (!_controller.isAnswered &&
                            !_controller.isFirstStagePassed &&
                            currentWord.isNotEmpty &&
                            _controller.flickedWord == null)
                          Positioned(
                            bottom: wordBottom,
                            child: isCompact
                                ? SizedBox(
                                    width: 110.w,
                                    height: 55.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: TopicDraggableWord(
                                        word: currentWord,
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        onFlick: (v) => _controller.handleFlick(
                                          v,
                                          currentWord,
                                          buckets,
                                          correctAnswer,
                                        ),
                                      ),
                                    ),
                                  )
                                : TopicDraggableWord(
                                        word: currentWord,
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        onFlick: (v) => _controller.handleFlick(
                                          v,
                                          currentWord,
                                          buckets,
                                          correctAnswer,
                                        ),
                                      )
                                      .animate(
                                        key: ValueKey(
                                          "word_${_controller.currentWordIndex}",
                                        ),
                                      )
                                      .move(
                                        begin: const Offset(0, -100),
                                        end: Offset.zero,
                                        duration: 500.ms,
                                        curve: Curves.bounceOut,
                                      )
                                      .fadeIn(),
                          ),
                        if (!_controller.isAnswered &&
                            !_controller.isFirstStagePassed &&
                            currentWord.isNotEmpty &&
                            _controller.flickedWord == null &&
                            _controller.currentWordIndex == 0 &&
                            _controller.userChoices.isEmpty)
                          Positioned(
                            bottom: wordBottom - 35.h,
                            child: IgnorePointer(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                        Icons
                                            .keyboard_double_arrow_left_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        size: 24.r,
                                      )
                                      .animate(onPlay: (c) => c.repeat())
                                      .fadeIn(duration: 500.ms)
                                      .fadeOut(delay: 500.ms),
                                  SizedBox(width: 8.w),
                                  Icon(
                                        Icons.touch_app_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        size: 32.r,
                                      )
                                      .animate(
                                        onPlay: (c) => c.repeat(reverse: true),
                                      )
                                      .moveX(
                                        begin: -25.w,
                                        end: 25.w,
                                        duration: 1200.ms,
                                        curve: Curves.easeInOutSine,
                                      ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                        Icons
                                            .keyboard_double_arrow_right_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        size: 24.r,
                                      )
                                      .animate(onPlay: (c) => c.repeat())
                                      .fadeIn(duration: 500.ms)
                                      .fadeOut(delay: 500.ms),
                                ],
                              ).animate().fadeIn(delay: 1.seconds, duration: 500.ms),
                            ),
                          ),
                        if (_controller.flickedWord != null)
                          Positioned(
                            bottom: flyingWordBottom,
                            left: _controller.flickTarget == 0 ? 40.w : null,
                            right: _controller.flickTarget == 1 ? 40.w : null,
                            child:
                                TopicDraggableWord(
                                      word: _controller.flickedWord!,
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      onFlick: (v) {},
                                    )
                                    .animate()
                                    .move(
                                      begin: Offset.zero,
                                      end: Offset(
                                        _controller.flickTarget == 0
                                            ? -(maxWidth / 2 - 70.w)
                                            : (maxWidth / 2 - 70.w),
                                        isCompact ? 100.h : 150.h,
                                      ),
                                      duration: 200.ms,
                                      curve: Curves.easeIn,
                                    )
                                    .scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(0.3, 0.3),
                                      duration: 250.ms,
                                    )
                                    .rotate(
                                      begin: 0,
                                      end: _controller.flickTarget == 0
                                          ? -0.2
                                          : 0.2,
                                      duration: 250.ms,
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
      },
    );
  }
}
