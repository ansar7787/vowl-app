import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_instruction_header.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_painters.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_warp_gate.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_word_shard.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_nuance_scale.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/context_sentence_builder.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

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
        TickerProviderStateMixin,
        GameScreenMixin<SynonymSearchScreen>,
        VocabularyGameScreenMixin<SynonymSearchScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final _scrollController = ScrollController();

  VocabularyQuest? _lastQuest;

  // Warp Interaction State
  final List<ValueNotifier<Offset>> _shardOffsets = [];
  final List<ValueNotifier<bool>> _isWarping = [];
  final List<ValueNotifier<List<Offset>>> _shardTrails = [];
  final ValueNotifier<int?> _activeShardIndex = ValueNotifier(null);
  BoxConstraints? _lastConstraints;
  bool _insideHapticZone = false;
  bool _isAnimatingFlight = false;
  bool _isDragging = false;
  Timer? _scrollTimer;
  Timer? _hintTimer;
  AnimationController? _flightController;

  void _ensureShardNotifiers(int count) {
    while (_shardOffsets.length < count) {
      _shardOffsets.add(ValueNotifier(Offset.zero));
    }
    while (_isWarping.length < count) {
      _isWarping.add(ValueNotifier(false));
    }
    while (_shardTrails.length < count) {
      _shardTrails.add(ValueNotifier([]));
    }
  }

  void _resetShardNotifiers() {
    _activeShardIndex.value = null;
    _insideHapticZone = false;
    for (var n in _shardOffsets) {
      n.value = Offset.zero;
    }
    for (var n in _isWarping) {
      n.value = false;
    }
    for (var n in _shardTrails) {
      n.value = [];
    }
  }

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  @override
  void dispose() {
    _flightController?.dispose();
    _isAnimatingFlight = false;
    _isDragging = false;
    _scrollTimer?.cancel();
    _hintTimer?.cancel();
    for (var n in _shardOffsets) {
      n.dispose();
    }
    for (var n in _isWarping) {
      n.dispose();
    }
    for (var n in _shardTrails) {
      n.dispose();
    }
    _activeShardIndex.dispose();
    _scrollController.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  void _onShardDragStart(int index, DragStartDetails details) {
    if (isAnsweredNotifier.value || _isWarping[index].value || _isAnimatingFlight) return;
    _isDragging = true;
    if (_activeShardIndex.value != index) {
      _activeShardIndex.value = index;
      hapticService.light();
    }
    _shardTrails[index].value = [];
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (isAnsweredNotifier.value || _activeShardIndex.value != index || _isAnimatingFlight) return;
    if (_lastConstraints == null) return;

    final currentOffset = _shardOffsets[index].value + details.delta;
    _shardOffsets[index].value = currentOffset;

    // Update trail
    final trail = List<Offset>.from(_shardTrails[index].value);
    trail.add(currentOffset);
    if (trail.length > 10) trail.removeAt(0);
    _shardTrails[index].value = trail;

    // Check for "near gate" haptic feedback
    final shardInitialPos = _getShardInitialPosition(
      index,
      (_lastQuest?.options?.length ?? 4),
      _lastConstraints!,
    );
    final currentPos = shardInitialPos + currentOffset;
    final distance = currentPos.distance;

    final isCompact = _lastConstraints != null && _lastConstraints!.maxHeight < 580;
    final hapticMax = isCompact ? 100.r : 115.r;
    final hapticMin = isCompact ? 75.r : 90.r;
    if (distance < hapticMax && distance > hapticMin) {
      if (!_insideHapticZone) {
        _insideHapticZone = true;
        hapticService.selection();
      }
    } else {
      _insideHapticZone = false;
    }
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    _isDragging = false;
    if (isAnsweredNotifier.value || _activeShardIndex.value != index || _isAnimatingFlight) {
      if (_shardOffsets.length > index && _shardOffsets[index].value != Offset.zero) {
        _shardOffsets[index].value = Offset.zero;
        _shardTrails[index].value = [];
      }
      return;
    }
    if (_lastConstraints == null) return;

    final isCompact = _lastConstraints!.maxHeight < 580;
    final currentOffset = _shardOffsets[index].value;
    final options = quest.options ?? [];
    final selectedText = options[index];

    final shardInitialPos = _getShardInitialPosition(
      index,
      options.length,
      _lastConstraints!,
    );
    final currentPos = shardInitialPos + currentOffset;

    final double snapDistance = isCompact ? 60.r : 85.r;
    if (currentPos.distance < snapDistance) {
      _warpShard(index, selectedText, quest);
    } else if (currentOffset.distance < 18.w) {
      // Touch jitter on low-end devices: finger barely moved (< 18.w).
      // Keep shard cleanly centered at its slot and retain selection!
      _shardOffsets[index].value = Offset.zero;
      _shardTrails[index].value = [];
    } else {
      // Snap back from an intentional but aborted drag
      _shardOffsets[index].value = Offset.zero;
      _shardTrails[index].value = [];
      _activeShardIndex.value = null;
      hapticService.light();
    }
  }

  void _onShardTapped(int index, VocabularyQuest quest) {
    if (isAnsweredNotifier.value || _isWarping[index].value || _isAnimatingFlight || _isDragging) return;

    if (_activeShardIndex.value == index) {
      // Tapping already-selected shard confirms and warps into center gate
      final options = quest.options ?? [];
      if (index < options.length) {
        _animateAndWarp(index, options[index], quest);
      }
      return;
    }

    _activeShardIndex.value = index;
    hapticService.light();
  }

  void _onWarpGateTapped(VocabularyQuest quest) {
    if (_activeShardIndex.value == null ||
        isAnsweredNotifier.value ||
        _isAnimatingFlight ||
        _isDragging ||
        _lastConstraints == null) {
      return;
    }
    final index = _activeShardIndex.value!;
    final options = quest.options ?? [];
    if (index >= options.length) return;

    _animateAndWarp(index, options[index], quest);
  }

  void _animateAndWarp(int index, String text, VocabularyQuest quest) {
    if (_isWarping[index].value || isAnsweredNotifier.value || _isAnimatingFlight) return;
    _isAnimatingFlight = true;

    final reduceMotion = !mounted
        ? true
        : VowlMotion.shouldReduceMotion(context);

    final startOffset = _shardOffsets[index].value;
    final initialPos = _lastConstraints != null
        ? _getShardInitialPosition(
            index,
            quest.options?.length ?? 4,
            _lastConstraints!,
          )
        : Offset.zero;
    final targetOffset = -initialPos;

    if (reduceMotion) {
      _shardOffsets[index].value = targetOffset;
      _isAnimatingFlight = false;
      _warpShard(index, text, quest);
      return;
    }

    _flightController?.dispose();
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    final curved = CurvedAnimation(
      parent: _flightController!,
      curve: Curves.easeInCubic,
    );

    curved.addListener(() {
      if (mounted) {
        _shardOffsets[index].value = Offset.lerp(
          startOffset,
          targetOffset,
          curved.value,
        )!;
      }
    });

    curved.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          _isAnimatingFlight = false;
          _warpShard(index, text, quest);
        }
      }
    });

    _flightController!.forward();
  }

  void _warpShard(int index, String text, VocabularyQuest quest) {
    _isWarping[index].value = true;
    _activeShardIndex.value = null;

    final correct = quest.correctAnswer?.trim().toLowerCase() ?? "";
    final isCorrect = text.trim().toLowerCase() == correct;

    if (isCorrect) {
      hapticService.selection(); // Subtle feedback for Phase 1
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      submitWrongAnswer(quest: quest, userAnswer: text);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, [GameQuest? quest]) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      final q = quest ?? _lastQuest;
      if (q != null) {
        submitWrongAnswer(quest: q);
      } else {
        submitWrongAnswer(quest: quest!, userAnswer: '');
      }
    }
  }

  Offset _getShardInitialPosition(
    int index,
    int total,
    BoxConstraints constraints,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final double safeWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : screenSize.width;
    final double safeHeight = constraints.maxHeight.isFinite
        ? math.max(constraints.maxHeight, 560.h)
        : (screenSize.height * 0.6);
    final isCompact = safeHeight < 580;

    final double maxShardHalfWidth = (isCompact ? 112.w : 124.w) / 2;
    final double minMargin = 16.w;
    final double maxAllowedHDist = (safeWidth / 2) - maxShardHalfWidth - minMargin;
    final double targetHDist = isCompact ? 80.w : 98.w;
    final double hDist = targetHDist.clamp(65.w, maxAllowedHDist);

    final double targetVDist = isCompact ? 82.h : 100.h;
    final double maxAllowedVDist = (safeHeight / 2) - (isCompact ? 45.h : 55.h);
    final double vDist = targetVDist.clamp(70.h, math.max(70.h, maxAllowedVDist));

    switch (index) {
      case 0:
        return Offset(-hDist, -vDist);
      case 1:
        return Offset(hDist, -vDist);
      case 2:
        return Offset(-hDist, vDist);
      case 3:
        return Offset(hDist, vDist);
      default:
        double angle = (index * (2 * math.pi / total)) - (math.pi / 2);
        return Offset(math.cos(angle) * hDist, math.sin(angle) * vDist);
    }
  }

  @override
  void onQuestionReset() {
    _flightController?.dispose();
    _flightController = null;
    _isAnimatingFlight = false;
    _isDragging = false;
    _scrollTimer?.cancel();
    _hintTimer?.cancel();
    _resetShardNotifiers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

        if (quest != null) {
          _ensureShardNotifiers(quest.options?.length ?? 0);
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: (state is VocabularyLoaded)
                  ? state.isFinalFailure
                  : false,
              showConfetti: showConfettiNotifier.value,
              hasStage2: true,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(NextQuestion()),
              useScrolling: false,
              disablePadding: true,
              onHint: () {
                if (_lastConstraints == null) return;
                final options = quest?.options ?? [];
                final correct = quest?.correctAnswer?.toLowerCase() ?? "";
                for (int i = 0; i < options.length; i++) {
                  if (options[i].toLowerCase() == correct) {
                    _shardOffsets[i].value =
                        _getShardInitialPosition(
                          i,
                          options.length,
                          _lastConstraints!,
                        ) *
                        -0.2;

                    _hintTimer?.cancel();
                    _hintTimer = Timer(1.seconds, () {
                      if (mounted && !isAnsweredNotifier.value) {
                        _shardOffsets[i].value = Offset.zero;
                      }
                    });
                    break;
                  }
                }
              },
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        _lastConstraints = constraints;

                        final screenSize = MediaQuery.sizeOf(context);
                        final double safeWidth = constraints.maxWidth.isFinite
                            ? constraints.maxWidth
                            : screenSize.width;
                        final double safeHeight =
                            constraints.maxHeight.isFinite
                            ? math.max(constraints.maxHeight, 560.h)
                            : (screenSize.height * 0.6);
                        final isCompact = safeHeight < 580;

                        return ValueListenableBuilder<bool>(
                          valueListenable: isFirstStagePassedNotifier,
                          builder: (context, isFirstStagePassed, _) {
                            return Stack(
                              children: [
                                RawScrollbar(
                                  controller: _scrollController,
                                  thumbColor: theme.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  radius: Radius.circular(8.r),
                                  thickness: 4.w,
                                  crossAxisMargin: 2.w,
                                  mainAxisMargin: 2.h,
                                  interactive: true,
                                  child: CustomScrollView(
                                    controller: _scrollController,
                                    physics: isFirstStagePassed
                                        ? const BouncingScrollPhysics()
                                        : const NeverScrollableScrollPhysics(),
                                    slivers: [
                                      SliverToBoxAdapter(
                                        child: Column(
                                          children: [
                                            IgnorePointer(
                                              ignoring: isFirstStagePassed,
                                              child: SizedBox(
                                                width: safeWidth,
                                                height: safeHeight,
                                                child: Stack(
                                              alignment: Alignment.center,
                                              clipBehavior: Clip.none,
                                              children: [
                                                Positioned.fill(
                                                  child: RepaintBoundary(
                                                    child: CustomPaint(
                                                      painter:
                                                          CosmicGridPainter(
                                                            theme.primaryColor
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                ValueListenableBuilder<int?>(
                                                  valueListenable:
                                                      _activeShardIndex,
                                                  builder: (
                                                    context,
                                                    activeIndex,
                                                    _,
                                                  ) {
                                                    final hasActiveSelection =
                                                        activeIndex != null;
                                                    return isCompact
                                                        ? Transform.scale(
                                                            scale: 0.8,
                                                            child:
                                                                SynonymWarpGate(
                                                              word:
                                                                  quest.word ??
                                                                  "",
                                                              color: theme
                                                                  .primaryColor,
                                                              isDark: isDark,
                                                              hasActiveSelection:
                                                                  hasActiveSelection,
                                                              onTap: () =>
                                                                  _onWarpGateTapped(
                                                                    quest,
                                                                  ),
                                                            ),
                                                          )
                                                        : SynonymWarpGate(
                                                            word:
                                                                quest.word ??
                                                                "",
                                                            color: theme
                                                                .primaryColor,
                                                            isDark: isDark,
                                                            hasActiveSelection:
                                                                hasActiveSelection,
                                                            onTap: () =>
                                                                _onWarpGateTapped(
                                                                  quest,
                                                                ),
                                                          );
                                                  },
                                                ),
                                                ...List.generate(quest.options?.length ?? 0, (
                                                  i,
                                                ) {
                                                  return ValueListenableBuilder<
                                                    List<Offset>
                                                  >(
                                                    valueListenable:
                                                        _shardTrails[i],
                                                    builder: (context, trail, child) {
                                                      return ValueListenableBuilder<
                                                        int?
                                                      >(
                                                        valueListenable:
                                                            _activeShardIndex,
                                                        builder: (context, activeIndex, _) {
                                                          if (activeIndex ==
                                                                  i &&
                                                              trail
                                                                  .isNotEmpty) {
                                                            final center =
                                                                Offset(
                                                                  safeWidth / 2,
                                                                  safeHeight /
                                                                      2,
                                                                );
                                                            final initialPos =
                                                                center +
                                                                _getShardInitialPosition(
                                                                  i,
                                                                  quest
                                                                      .options!
                                                                      .length,
                                                                  constraints,
                                                                );
                                                            final absoluteTrail =
                                                                trail
                                                                    .map(
                                                                      (
                                                                        offset,
                                                                      ) =>
                                                                          initialPos +
                                                                          offset,
                                                                    )
                                                                    .toList();

                                                            return Positioned.fill(
                                                              child: IgnorePointer(
                                                                child: CustomPaint(
                                                                  painter: TrailPainter(
                                                                    absoluteTrail,
                                                                    theme
                                                                        .primaryColor,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                          return const SizedBox.shrink();
                                                        },
                                                      );
                                                    },
                                                  );
                                                }),
                                                ...List.generate(
                                                  quest.options?.length ?? 0,
                                                  (i) {
                                                    final center = Offset(
                                                      safeWidth / 2,
                                                      safeHeight / 2,
                                                    );
                                                    final initialPos =
                                                        center +
                                                        _getShardInitialPosition(
                                                          i,
                                                          quest.options!.length,
                                                          constraints,
                                                        );

                                                    return SynonymWordShard(
                                                      index: i,
                                                      text: quest.options![i],
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      initialPos: initialPos,
                                                      offsetNotifier:
                                                          _shardOffsets[i],
                                                      isWarpingNotifier:
                                                          _isWarping[i],
                                                      activeIndexNotifier:
                                                          _activeShardIndex,
                                                      isCompact: isCompact,
                                                      onPanStart: (d) =>
                                                          _onShardDragStart(
                                                            i,
                                                            d,
                                                          ),
                                                      onPanUpdate: (d) =>
                                                          _onShardDragUpdate(
                                                            i,
                                                            d,
                                                          ),
                                                      onPanEnd: () =>
                                                          _onShardDragEnd(
                                                            i,
                                                            quest,
                                                          ),
                                                      onTap: () =>
                                                          _onShardTapped(
                                                            i,
                                                            quest,
                                                          ),
                                                    );
                                                  },
                                                ),
                                                Positioned(
                                                  top: isCompact ? 2.h : 10.h,
                                                  left: 16.w,
                                                  right: 16.w,
                                                  child: IgnorePointer(
                                                    child: SynonymInstructionHeader(
                                                      color: theme.primaryColor,
                                                      instruction:
                                                          quest
                                                              .instruction
                                                              .isNotEmpty
                                                          ? InstructionHelper.getInstruction(
                                                              quest,
                                                            )
                                                          : "Find the matching synonym",
                                                      isCompact: isCompact,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isFirstStagePassedNotifier.value)
                                          Column(
                                            children: [
                                              SizedBox(height: 10.h),
                                              if (quest.explanation != null &&
                                                  quest.explanation!.isNotEmpty)
                                                SynonymNuanceScale(
                                                  targetWord: quest.word ?? "",
                                                  synonymWord:
                                                      quest.correctAnswer ?? "",
                                                  explanation:
                                                      quest.explanation!,
                                                  primaryColor:
                                                      theme.primaryColor,
                                                ),
                                            ],
                                          ),
                                        SizedBox(
                                          height:
                                              (isFirstStagePassedNotifier
                                                      .value &&
                                                  !isAnsweredNotifier.value)
                                              ? 24.h
                                              : 60.h,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isFirstStagePassedNotifier.value &&
                                      !isAnsweredNotifier.value)
                                    SliverToBoxAdapter(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            left: 16.w,
                                            right: 16.w,
                                            bottom: 24.h,
                                          ),
                                          child: ContextSentenceBuilder(
                                            targetKeyword:
                                                quest.correctAnswer ?? "",
                                            primaryColor: theme.primaryColor,
                                            acceptedKeywordForms:
                                                quest.synonyms ??
                                                [quest.correctAnswer ?? ""],
                                            onConfirmed: () =>
                                                _submitVerbalEvaluation(
                                                  true,
                                                  quest,
                                                ),
                                            onSkipped: () =>
                                                _submitVerbalEvaluation(
                                                  false,
                                                  quest,
                                                ),
                                            isPositioned: false,
                                            exampleSentence:
                                                quest.contextSentence,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
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
