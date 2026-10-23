import 'dart:async';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_painters.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_nebula_core.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_option_shard.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_gradient_scale.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_instruction_header.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/utils/instruction_helper.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color00e5ff = Color(0xFF00E5FF);
}

/// Interactive antonym search game screen where learners match target words with polar opposites.
class AntonymSearchScreen extends StatefulWidget {
  /// The active curriculum difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Creates an [AntonymSearchScreen] instance.
  const AntonymSearchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.antonymSearch,
  });
  @override
  State<AntonymSearchScreen> createState() => _AntonymSearchScreenState();
}

class _AntonymSearchScreenState extends State<AntonymSearchScreen>
    with
        GameScreenMixin<AntonymSearchScreen>,
        VocabularyGameScreenMixin<AntonymSearchScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<bool> _isDragPassed = ValueNotifier(false);

  VocabularyQuest? _lastQuest;
  bool _isAnimatingTap = false;
  bool _isDraggingShard = false;
  int? _hapticZoneIndex;

  final Map<int, ValueNotifier<Offset>> _shardOffsets = {};
  final Map<int, ValueNotifier<bool>> _isFused = {};
  final ValueNotifier<int?> _activeShardIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
  BoxConstraints? _lastConstraints;
  Timer? _tapAnimationTimer;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  @override
  void dispose() {
    _tapAnimationTimer?.cancel();
    _scrollTimer?.cancel();
    _isDragPassed.dispose();
    _activeShardIndex.dispose();
    _scrollController.dispose();
    _disposeShardNotifiers();
    disposeVocabularyGame();
    super.dispose();
  }

  void _disposeShardNotifiers() {
    for (var n in _shardOffsets.values) {
      n.dispose();
    }
    for (var n in _isFused.values) {
      n.dispose();
    }
    _shardOffsets.clear();
    _isFused.clear();
  }

  void _ensureShardNotifiers(int count) {
    for (int i = 0; i < count; i++) {
      _shardOffsets.putIfAbsent(i, () => ValueNotifier(Offset.zero));
      _isFused.putIfAbsent(i, () => ValueNotifier(false));
    }
  }

  @override
  void onQuestionReset() {
    _tapAnimationTimer?.cancel();
    _scrollTimer?.cancel();
    _isDragPassed.value = false;
    _activeShardIndex.value = null;
    _isAnimatingTap = false;
    _isDraggingShard = false;
    _hapticZoneIndex = null;
    for (var n in _shardOffsets.values) {
      n.value = Offset.zero;
    }
    for (var n in _isFused.values) {
      n.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetColor = _LocalPalette.color00e5ff;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: onVocabularyStateChanged,
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoaded) {
          _lastQuest = state.currentQuestOrNull;
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuestOrNull
            : _lastQuest;

        if (quest?.options != null) {
          _ensureShardNotifiers(quest!.options!.length);
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _isDragPassed,
          ]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is VocabularyLoaded
                  ? state.isFinalFailure
                  : false,
              showConfetti: showConfettiNotifier.value,
              hasStage2: true,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(const NextQuestion()),
              onHint: () {},
              useScrolling: false,
              disablePadding: true,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        _lastConstraints = constraints;
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 580;

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
                                physics: (!_isDragPassed.value)
                                    ? const NeverScrollableScrollPhysics()
                                    : const BouncingScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height: constraints.maxHeight,
                                      child: IgnorePointer(
                                        ignoring: _isDragPassed.value,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: FluxGridPainter(
                                                  isDark,
                                                ),
                                              ),
                                            ),

                                            Positioned(
                                              top: isCompact ? 4.h : 12.h,
                                              left: 16.w,
                                              right: 16.w,
                                              child: IgnorePointer(
                                                child: AntonymInstructionHeader(
                                                  color: theme.primaryColor,
                                                  instruction: quest.instruction.isNotEmpty
                                                      ? InstructionHelper.getInstruction(quest)
                                                      : "Find the opposite word",
                                                  isCompact: isCompact,
                                                ),
                                              ),
                                            ),

                                            Center(
                                              child: GestureDetector(
                                                onTap: _onCoreTapped,
                                                child: isCompact
                                                    ? SizedBox(
                                                        width: 140.w,
                                                        height: 140.w,
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child:
                                                              AntonymNebulaCore(
                                                                word:
                                                                    quest
                                                                        .word ??
                                                                    "",
                                                                color:
                                                                    targetColor,
                                                                isDark: isDark,
                                                              ),
                                                        ),
                                                      )
                                                    : AntonymNebulaCore(
                                                        word: quest.word ?? "",
                                                        color: targetColor,
                                                        isDark: isDark,
                                                      ),
                                              ),
                                            ),

                                            ...List.generate(
                                              quest.options?.length ?? 0,
                                              (i) {
                                                if (_shardOffsets[i] == null ||
                                                    _isFused[i] == null) {
                                                  return const SizedBox.shrink();
                                                }
                                                return ListenableBuilder(
                                                  listenable: Listenable.merge([
                                                    _shardOffsets[i]!,
                                                    _isFused[i]!,
                                                    _activeShardIndex,
                                                  ]),
                                                  builder: (context, _) {
                                                    final isSelected =
                                                        _activeShardIndex.value == i;
                                                    return AntonymOptionShard(
                                                      index: i,
                                                      text: quest.options![i],
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      initialPos:
                                                          _getInitialPosition(
                                                            i,
                                                          ),
                                                      offset: _shardOffsets[i]!
                                                          .value,
                                                      isDragging:
                                                          _isDraggingShard &&
                                                              isSelected,
                                                      isSelected: isSelected,
                                                      isCompact: isCompact,
                                                      isFused:
                                                          _isFused[i]!.value,
                                                      onPanStart: () =>
                                                          _onShardStart(i),
                                                      onPanUpdate: (d) =>
                                                          _onShardUpdate(i, d),
                                                      onPanEnd: () =>
                                                          _onShardEnd(i),
                                                      onTap: () =>
                                                          _onShardTapped(i),
                                                    );
                                                  },
                                                );
                                              },
                                            ),

                                            ...List.generate(
                                              quest.options?.length ?? 0,
                                              (i) {
                                                if (_shardOffsets[i] == null) {
                                                  return const SizedBox.shrink();
                                                }
                                                return ValueListenableBuilder<
                                                  int?
                                                >(
                                                  valueListenable:
                                                      _activeShardIndex,
                                                  builder: (context, activeIndex, _) {
                                                    final isActive =
                                                        activeIndex == i;
                                                    return ValueListenableBuilder<
                                                      Offset
                                                    >(
                                                      valueListenable:
                                                          _shardOffsets[i]!,
                                                      builder: (context, offset, _) {
                                                        return AnimatedOpacity(
                                                          opacity: isActive
                                                              ? 1.0
                                                              : 0.0,
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    150,
                                                              ),
                                                          child:
                                                              _buildPlasmaThunder(
                                                                i,
                                                                targetColor,
                                                                offset,
                                                              ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isDragPassed.value &&
                                      !isAnsweredNotifier.value)
                                    SliverToBoxAdapter(
                                      child: Column(
                                        children: [
                                          if (quest.gradientScale != null &&
                                              quest.gradientScale!.isNotEmpty)
                                            AntonymGradientScale(
                                              gradientScale:
                                                  quest.gradientScale!,
                                              primaryColor: theme.primaryColor,
                                            ),
                                          if (quest.explanation != null &&
                                              quest
                                                  .explanation!
                                                  .isNotEmpty) ...[
                                            SizedBox(height: 16.h),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20.w,
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(16.r),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.05,
                                                        )
                                                      : Colors.black.withValues(
                                                          alpha: 0.03,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.r,
                                                      ),
                                                  border: Border.all(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .lightbulb_outline_rounded,
                                                      color: theme.primaryColor,
                                                      size: 20.r,
                                                    ),
                                                    SizedBox(width: 12.w),
                                                    Expanded(
                                                      child: Text(
                                                        quest.explanation!,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 14.sp,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: isDark
                                                              ? Colors.white70
                                                              : Colors.black87,
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                          SizedBox(height: 24.h),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20.w,
                                            ),
                                            child: SpeakToConfirmOverlay(
                                            expectedText:
                                                "${quest.word} ${quest.correctAnswer}",
                                            displayText:
                                                "${quest.word?.toUpperCase()}   ↔   ${quest.correctAnswer?.toUpperCase()}",
                                            primaryColor: theme.primaryColor,
                                            onConfirmed: () =>
                                                _submitVerbalEvaluation(
                                                  true,
                                                  quest: quest,
                                                ),
                                            onSkipped: () =>
                                                _submitVerbalEvaluation(
                                                  false,
                                                  quest: quest,
                                                ),
                                            isPositioned: false,
                                          ),
                                        ),
                                        SizedBox(height: 60.h),
                                        ],
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

  Offset _getInitialPosition(int index) {
    if (_lastConstraints == null) return Offset.zero;
    final w = _lastConstraints!.maxWidth;
    final h = _lastConstraints!.maxHeight;
    final isLeft = index % 2 == 0;
    final int total = _lastQuest?.options?.length ?? 4;
    final isCompact = h < 580;

    final double maxShardHalfWidth = (isCompact ? 116.w : 128.w) / 2;
    final double minMargin = 16.w;
    final double maxAllowedHDist = (w / 2) - maxShardHalfWidth - minMargin;
    final double targetHDist = w * 0.25;
    final double hDist = targetHDist.clamp(
      50.w,
      maxAllowedHDist > 50.w ? maxAllowedHDist : (w / 2) - maxShardHalfWidth,
    );

    double yPos;
    if (total <= 4) {
      final isBottomHalf = index >= (total / 2).ceil();
      yPos = h * (isBottomHalf ? 0.75 : 0.25);
    } else {
      if (index < 2) {
        yPos = h * 0.15;
      } else if (index < 4) {
        yPos = h * 0.32;
      } else if (index < 6) {
        yPos = h * 0.68;
      } else {
        yPos = h * 0.85;
      }
    }

    return Offset(isLeft ? ((w / 2) - hDist) : ((w / 2) + hDist), yPos);
  }

  void _onShardStart(int index) {
    if (isAnsweredNotifier.value ||
        _isDragPassed.value ||
        _isAnimatingTap ||
        _isFused[index]?.value == true) {
      return;
    }
    _isDraggingShard = true;
    if (_activeShardIndex.value != index) {
      _activeShardIndex.value = index;
      hapticService.light();
    }
  }

  void _onShardUpdate(int index, DragUpdateDetails details) {
    if (_activeShardIndex.value != index || _isAnimatingTap) return;
    if (_shardOffsets[index] != null) {
      _shardOffsets[index]!.value += details.delta;
      final initial = _getInitialPosition(index);
      final currentY = initial.dy + _shardOffsets[index]!.value.dy;
      final maxHeight = _lastConstraints?.maxHeight ?? 600;

      final triggerTop = maxHeight * 0.35;
      final triggerBottom = maxHeight * 0.65;

      final inZone = currentY > triggerTop && currentY < triggerBottom;
      if (inZone && _hapticZoneIndex != index) {
        hapticService.selection();
        _hapticZoneIndex = index;
      } else if (!inZone && _hapticZoneIndex == index) {
        _hapticZoneIndex = null;
      }
    }
  }

  void _onShardEnd(int index) {
    _isDraggingShard = false;
    if (_activeShardIndex.value != index || _lastConstraints == null || _isAnimatingTap) return;
    final initial = _getInitialPosition(index);
    final offset = _shardOffsets[index]?.value ?? Offset.zero;
    final currentY = initial.dy + offset.dy;

    final maxHeight = _lastConstraints!.maxHeight;
    final bool nearCenter =
        currentY > maxHeight * 0.35 && currentY < maxHeight * 0.65;

    if (nearCenter) {
      _evaluateShard(index);
    } else if (offset.distance < 18.w) {
      // Touch jitter on low-end devices: finger barely moved (< 18.w).
      // Keep shard cleanly centered at its slot and retain selection!
      if (_shardOffsets[index] != null) {
        _shardOffsets[index]!.value = Offset.zero;
      }
    } else {
      if (_shardOffsets[index] != null) {
        _shardOffsets[index]!.value = Offset.zero;
      }
      _activeShardIndex.value = null;
      hapticService.light();
    }
  }

  void _onShardTapped(int index) {
    if (isAnsweredNotifier.value ||
        _isDragPassed.value ||
        _isAnimatingTap ||
        _isFused[index]?.value == true) {
      return;
    }

    if (_activeShardIndex.value == index) {
      // Tapping already-selected shard confirms and fuses into core!
      _animateTapToCore(index);
      return;
    }

    _activeShardIndex.value = index;
    hapticService.light();
  }

  void _onCoreTapped() {
    if (_activeShardIndex.value == null ||
        isAnsweredNotifier.value ||
        _isDragPassed.value ||
        _isAnimatingTap ||
        _lastConstraints == null) {
      return;
    }

    final activeIndex = _activeShardIndex.value!;
    _animateTapToCore(activeIndex);
  }

  void _animateTapToCore(int index) {
    if (_lastConstraints == null || _isAnimatingTap) return;
    _isAnimatingTap = true;
    _activeShardIndex.value = null; // trigger animation

    final initial = _getInitialPosition(index);
    final center = Offset(
      _lastConstraints!.maxWidth / 2,
      _lastConstraints!.maxHeight / 2,
    );
    _shardOffsets[index]?.value = center - initial;

    _tapAnimationTimer?.cancel();
    _tapAnimationTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _isAnimatingTap = false;
        _evaluateShard(index);
      }
    });
  }

  void _evaluateShard(int index) {
    if (_lastQuest == null ||
        _lastQuest!.options == null ||
        index >= _lastQuest!.options!.length) {
      return;
    }
    final bool isAntonym =
        _lastQuest!.options![index].trim().toLowerCase() ==
        _lastQuest!.correctAnswer?.trim().toLowerCase();

    if (isAntonym) {
      _onSuccess(index);
    } else {
      _onFailure(index);
    }
  }

  void _onSuccess(int index) {
    hapticService.selection();
    if (_isFused[index] != null) {
      _isFused[index]!.value = true;
    }
    _isDragPassed.value = true;
    _activeShardIndex.value = null;

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

  void _submitVerbalEvaluation(bool nailedIt, {GameQuest? quest}) {
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

  void _onFailure(int index) {
    if (_shardOffsets[index] != null) {
      _shardOffsets[index]!.value = Offset.zero;
    }
    _activeShardIndex.value = null;

    final quest = _lastQuest;
    if (quest != null) {
      final userAnswer =
          (quest.options != null && index < quest.options!.length)
          ? quest.options![index]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    } else {
      submitWrongAnswer(quest: quest!, userAnswer: '');
    }
  }

  Widget _buildPlasmaThunder(
    int activeIndex,
    Color targetColor,
    Offset offset,
  ) {
    if (_lastConstraints == null) return const SizedBox.shrink();

    final initial = _getInitialPosition(activeIndex);
    final current = initial + offset;
    final maxHeight = _lastConstraints!.maxHeight;
    // Connect the dragged shard directly to the central core
    final corePosition = Offset(_lastConstraints!.maxWidth / 2, maxHeight / 2);

    return IgnorePointer(
      child: CustomPaint(
        painter: PlasmaArcPainter(current, corePosition, targetColor),
      ),
    );
  }
}
