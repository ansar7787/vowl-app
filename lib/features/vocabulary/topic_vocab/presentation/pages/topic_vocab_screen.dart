import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

// Extracted Optimized Widgets
import '../widgets/topic_machine_head.dart';
import '../widgets/topic_containment_bin.dart';
import '../widgets/topic_batch_counter.dart';
import '../widgets/topic_draggable_core.dart';
import '../controllers/topic_vocab_controller.dart';

/// Interactive topic categorization game screen where learners flick words into matching categorical containment bins.
class TopicVocabScreen extends StatefulWidget {
  /// The active curriculum difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Creates a [TopicVocabScreen] instance.
  const TopicVocabScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.topicVocab,
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

  late final TopicVocabController _controller;
  VocabularyQuest? _lastQuest;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TopicVocabController(
      hapticService: di.sl<HapticService>(),
      soundService: di.sl<SoundService>(),
      onSubmitAnswer: (nailedIt, {quest, userAnswer}) {
        if (nailedIt) {
          submitCorrectAnswer();
        } else {
          final q = quest ?? _lastQuest ?? _controller.currentQuest;
          if (q != null) {
            submitWrongAnswer(quest: q, userAnswer: userAnswer);
          } else {
            submitWrongAnswer(quest: quest!, userAnswer: '');
          }
        }
      },
    );
    initVocabularyGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    final state = context.read<VocabularyBloc>().state;
    if (state is VocabularyLoaded) {
      _controller.reset(state.currentQuestOrNull);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: onVocabularyStateChanged,
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoaded) {
          _lastQuest = state.currentQuest;
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        if (quest != null && _controller.currentQuest != quest) {
          _controller.reset(quest);
        }

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

            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _controller.isAnswered,
              isCorrect: _controller.isCorrect,
              showConfetti: _controller.showConfetti,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(NextQuestion()),
              useScrolling: false,
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
                  final counterTop = isCompact ? 10.h : maxHeight * 0.04;
                  final instructionTop = isCompact ? 44.h : maxHeight * 0.10;
                  final machineTop = isCompact ? 100.h : maxHeight * 0.22;

                  // Word is positioned relative to bottom to work nicely with flicking physics
                  final wordBottom = isCompact ? 135.h : maxHeight * 0.38;
                  final flyingWordBottom = isCompact ? 135.h : maxHeight * 0.38;
                  final binBottom = isCompact ? 10.h : maxHeight * 0.04;

                  return RawScrollbar(
                    controller: _scrollController,
                    thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                    radius: Radius.circular(8.r),
                    thickness: 4.w,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: SizedBox(
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

                                // 2. INSTRUCTION BANNER
                                if (quest != null)
                                  Positioned(
                                    top: instructionTop,
                                    left: 16.w,
                                    right: 16.w,
                                    child: RepaintBoundary(
                                      child: Center(
                                        child: _TopicInstructionBanner(
                                          primaryColor: theme.primaryColor,
                                          quest: quest,
                                        ),
                                      ),
                                    ),
                                  ),

                                // 3. EMISSION MACHINE
                                Positioned(
                                  top: machineTop,
                                  child: RepaintBoundary(
                                    child: _CompactFit(
                                      isCompact: isCompact,
                                      height: 75.h,
                                      child: TopicMachineHead(
                                        primaryColor: theme.primaryColor,
                                        emoji: quest?.topicEmoji ?? "📦",
                                      ),
                                    ),
                                  ),
                                ),

                                // Containment Bins
                                Positioned(
                                  bottom: binBottom,
                                  left: 8
                                      .w, // Added premium visual margin from the edge
                                  child: Semantics(
                                    button: true,
                                    label: 'Sort into ${buckets[0]}',
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        if (!_controller.isAnswered &&
                                            !_controller.isFirstStagePassed &&
                                            currentWord.isNotEmpty &&
                                            _controller.flickedWord == null) {
                                          _controller.handleFlick(
                                            -1000,
                                            0,
                                            currentWord,
                                            buckets,
                                          );
                                        }
                                      },
                                      child: RepaintBoundary(
                                        child: _CompactFit(
                                          isCompact: isCompact,
                                          width: 110.w,
                                          height: 140.h,
                                          child: TopicContainmentBin(
                                            index: 0,
                                            label: buckets[0],
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            words:
                                                _controller.wordsInBins[0] ??
                                                [],
                                            isHinted: _controller.isHintTarget(
                                              currentWord,
                                              buckets[0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (buckets.length > 1)
                                  Positioned(
                                    bottom: binBottom,
                                    right: 8.w,
                                    child: Semantics(
                                      button: true,
                                      label: 'Sort into ${buckets[1]}',
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          if (!_controller.isAnswered &&
                                              !_controller.isFirstStagePassed &&
                                              currentWord.isNotEmpty &&
                                              _controller.flickedWord == null) {
                                            _controller.handleFlick(
                                              1000,
                                              0,
                                              currentWord,
                                              buckets,
                                            );
                                          }
                                        },
                                        child: RepaintBoundary(
                                          child: _CompactFit(
                                            isCompact: isCompact,
                                            width: 110.w,
                                            height: 140.h,
                                            child: TopicContainmentBin(
                                              index: 1,
                                              label: buckets[1],
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                              words:
                                                  _controller.wordsInBins[1] ??
                                                  [],
                                              isHinted: _controller
                                                  .isHintTarget(
                                                    currentWord,
                                                    buckets[1],
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!_controller.isAnswered &&
                                    !_controller.isFirstStagePassed &&
                                    currentWord.isNotEmpty &&
                                    _controller.flickedWord == null)
                                  Positioned(
                                    bottom: wordBottom,
                                    child: Builder(
                                      builder: (context) {
                                        final word = TopicDraggableWord(
                                          word: currentWord,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          onFlick: (v, offset) =>
                                              _controller.handleFlick(
                                                v,
                                                offset,
                                                currentWord,
                                                buckets,
                                              ),
                                        );
                                        if (isCompact) {
                                          return SizedBox(
                                            width: 110.w,
                                            height: 55.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: word,
                                            ),
                                          );
                                        }
                                        if (reduceMotion) {
                                          return word;
                                        }
                                        return word
                                            .animate(
                                              key: ValueKey(
                                                "word_${_controller.currentWordIndex}",
                                              ),
                                            )
                                            .move(
                                              begin: const Offset(0, -100),
                                              end: Offset.zero,
                                              duration: 500.ms,
                                              curve: Curves.easeOutCubic,
                                            )
                                            .fadeIn();
                                      },
                                    ),
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
                                      child: Builder(
                                        builder: (context) {
                                          final arrowColor = isDark
                                              ? Colors.white.withValues(alpha: 0.5)
                                              : theme.primaryColor.withValues(alpha: 0.5);
                                          final handIconColor = isDark
                                              ? Colors.white.withValues(alpha: 0.9)
                                              : theme.primaryColor;

                                          final leftArrow = Icon(
                                            Icons.keyboard_double_arrow_left_rounded,
                                            color: arrowColor,
                                            size: 24.r,
                                          );
                                          final handIcon = Icon(
                                            Icons.touch_app_rounded,
                                            color: handIconColor,
                                            size: 32.r,
                                          );
                                          final rightArrow = Icon(
                                            Icons.keyboard_double_arrow_right_rounded,
                                            color: arrowColor,
                                            size: 24.r,
                                          );

                                          final row = Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              reduceMotion
                                                  ? leftArrow
                                                  : leftArrow
                                                      .animate(
                                                        onPlay: (c) => c.repeat(),
                                                      )
                                                      .fadeIn(duration: 500.ms)
                                                      .fadeOut(delay: 500.ms),
                                              SizedBox(width: 8.w),
                                              reduceMotion
                                                  ? handIcon
                                                  : handIcon
                                                      .animate(
                                                        onPlay: (c) =>
                                                            c.repeat(reverse: true),
                                                      )
                                                      .moveX(
                                                        begin: -25.w,
                                                        end: 25.w,
                                                        duration: 1200.ms,
                                                        curve: Curves.easeInOutSine,
                                                      ),
                                              SizedBox(width: 8.w),
                                              reduceMotion
                                                  ? rightArrow
                                                  : rightArrow
                                                      .animate(
                                                        onPlay: (c) => c.repeat(),
                                                      )
                                                      .fadeIn(duration: 500.ms)
                                                      .fadeOut(delay: 500.ms),
                                            ],
                                          );

                                          return reduceMotion
                                              ? row
                                              : row.animate().fadeIn(
                                                  delay: 1.seconds,
                                                  duration: 500.ms,
                                                );
                                        },
                                      ),
                                    ),
                                  ),
                                if (_controller.flickedWord != null)
                                  Positioned(
                                    bottom: flyingWordBottom,
                                    child: Builder(
                                      builder: (context) {
                                        final flyingWord = TopicDraggableWord(
                                          word: _controller.flickedWord!,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          onFlick: (v, offset) {},
                                        );
                                        if (reduceMotion) {
                                          return flyingWord;
                                        }
                                        return flyingWord
                                            .animate()
                                            .move(
                                              begin: Offset(
                                                _controller.flickStartOffset ??
                                                    0,
                                                0,
                                              ),
                                              end: Offset(
                                                _controller.flickTarget == 0
                                                    ? -(maxWidth / 2 - 78.w)
                                                    : (maxWidth / 2 - 78.w),
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
                                            );
                                      },
                                    ),
                                  ),
                              ],
                            ),
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

// ─── Instruction banner ───────────────────────────────────────────────────────

class _TopicInstructionBanner extends StatelessWidget {
  final Color primaryColor;
  final VocabularyQuest quest;

  const _TopicInstructionBanner({
    required this.primaryColor,
    required this.quest,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    final rawInstruction = InstructionHelper.getInstruction(quest).trim();
    final instruction = rawInstruction.isNotEmpty
        ? rawInstruction
        : 'Sort each word into the correct category.';

    final bannerContent = Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? primaryColor.withValues(alpha: 0.12)
            : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Text(
        instruction,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : primaryColor,
          height: 1.35,
          letterSpacing: 0.2,
        ),
      ),
    );

    return reduceMotion
        ? bannerContent
        : bannerContent
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: -0.15, end: 0, curve: Curves.easeOut);
  }
}

// ─── Compact layout wrapper ───────────────────────────────────────────────────

/// Wraps [child] in a constrained [FittedBox] when [isCompact] is true,
/// eliminating the repeated `isCompact ? SizedBox(FittedBox(child)) : child`
/// ternary pattern.
class _CompactFit extends StatelessWidget {
  final bool isCompact;
  final double? width;
  final double? height;
  final Widget child;

  const _CompactFit({
    required this.isCompact,
    this.width,
    this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCompact) return child;
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}
