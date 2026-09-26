import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
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

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  @override
  void dispose() {
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
    if (isAnsweredNotifier.value || _isWarping[index].value) return;
    _activeShardIndex.value = index;
    _shardTrails[index].value = [];
    hapticService.light();
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (isAnsweredNotifier.value || _activeShardIndex.value != index) return;
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

    if (distance < 120.r && distance > 100.r) {
      if (!_insideHapticZone) {
        _insideHapticZone = true;
        hapticService.selection();
      }
    } else {
      _insideHapticZone = false;
    }
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    if (isAnsweredNotifier.value || _activeShardIndex.value != index) return;
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

    final double snapDistance = isCompact ? 65.r : 100.r;
    if (currentPos.distance < snapDistance) {
      _warpShard(index, selectedText, quest);
    } else {
      // Snap back
      _shardOffsets[index].value = Offset.zero;
      _shardTrails[index].value = [];
      _activeShardIndex.value = null;
      hapticService.light();
    }
  }

  void _onShardTapped(int index) {
    if (isAnsweredNotifier.value || _isWarping[index].value) return;
    _activeShardIndex.value = index;
    hapticService.light();
  }

  void _onWarpGateTapped(VocabularyQuest quest) {
    if (_activeShardIndex.value == null ||
        isAnsweredNotifier.value ||
        _lastConstraints == null) {
      return;
    }
    final index = _activeShardIndex.value!;
    final options = quest.options ?? [];
    if (index >= options.length) return;

    _warpShard(index, options[index], quest);
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
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  Offset _getShardInitialPosition(
    int index,
    int total,
    BoxConstraints constraints,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final double safeWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : screenSize.width;
    final double safeHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : (screenSize.height * 0.6);
    final isCompact = safeHeight < 580;

    double hDist = (safeWidth - 100.w) / 2;
    double vDist = (safeHeight - (isCompact ? 95.h : 120.h)) / 2;

    hDist = hDist.clamp(isCompact ? 65.w : 90.w, 130.w);
    vDist = vDist.clamp(isCompact ? 90.h : 120.h, 140.h);

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

  double _lastKeyboardHeight = 0;

  @override
  void onQuestionReset() {
    _activeShardIndex.value = null;
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

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

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

                    Future.delayed(1.seconds, () {
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
                        final keyboardHeight = MediaQuery.of(
                          context,
                        ).viewInsets.bottom;

                        if (keyboardHeight > 0 && _lastKeyboardHeight == 0) {
                          _scrollToBottom();
                        }
                        _lastKeyboardHeight = keyboardHeight;

                        final screenSize = MediaQuery.of(context).size;
                        final double safeWidth = constraints.maxWidth.isFinite
                            ? constraints.maxWidth
                            : screenSize.width;
                        final double safeHeight =
                            (constraints.maxHeight.isFinite
                            ? constraints.maxHeight
                            : (screenSize.height * 0.6));
                        final isCompact = safeHeight < 580;

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
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        IgnorePointer(
                                          ignoring:
                                              isFirstStagePassedNotifier.value,
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
                                                isCompact
                                                    ? Transform.scale(
                                                        scale: 0.8,
                                                        child: SynonymWarpGate(
                                                          word:
                                                              quest.word ?? "",
                                                          color: theme
                                                              .primaryColor,
                                                          isDark: isDark,
                                                          onTap: () =>
                                                              _onWarpGateTapped(
                                                                quest,
                                                              ),
                                                        ),
                                                      )
                                                    : SynonymWarpGate(
                                                        word: quest.word ?? "",
                                                        color:
                                                            theme.primaryColor,
                                                        isDark: isDark,
                                                        onTap: () =>
                                                            _onWarpGateTapped(
                                                              quest,
                                                            ),
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
                                                          _onShardTapped(i),
                                                    );
                                                  },
                                                ),
                                                Positioned(
                                                  top: isCompact ? 2.h : 10.h,
                                                  left: 16.w,
                                                  right: 16.w,
                                                  child: SynonymInstructionHeader(
                                                    color: theme.primaryColor,
                                                    instruction:
                                                        quest
                                                            .instruction
                                                            .isNotEmpty
                                                        ? InstructionHelper.getInstruction(
                                                            quest,
                                                          )
                                                        : "WARP THE SYNONYM SHARD",
                                                    hint: quest.hint,
                                                    isCompact: isCompact,
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
                                            bottom: 24.h + keyboardHeight,
                                          ),
                                          child: ContextSentenceBuilder(
                                            targetKeyword:
                                                quest.correctAnswer ?? "",
                                            primaryColor: theme.primaryColor,
                                            acceptedKeywordForms:
                                                quest.synonyms ??
                                                [quest.correctAnswer ?? ""],
                                            onConfirmed: () =>
                                                _submitVerbalEvaluation(true),
                                            onSkipped: () =>
                                                _submitVerbalEvaluation(false),
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
                    ),
            );
          },
        );
      },
    );
  }
}
