import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_instruction_header.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_painters.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_warp_gate.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_word_shard.dart';
import 'package:vowl/core/presentation/widgets/dynamic_anagram_wrapper.dart';

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
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isFirstStagePassed = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  // Warp Interaction State
  final Map<int, Offset> _shardOffsets = {};
  final Map<int, bool> _isWarping = {};
  final Map<int, List<Offset>> _shardTrails = {};
  int? _activeShardIndex;
  BoxConstraints? _lastConstraints;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _initShards(int count) {
    _shardOffsets.clear();
    _isWarping.clear();
    _shardTrails.clear();
    for (int i = 0; i < count; i++) {
      _shardOffsets[i] = Offset.zero;
      _isWarping[i] = false;
      _shardTrails[i] = [];
    }
  }

  void _onShardDragStart(int index, DragStartDetails details) {
    if (_isAnswered || _isWarping[index] == true) return;
    setState(() {
      _activeShardIndex = index;
      _shardTrails[index] = [];
    });
    _hapticService.light();
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (_isAnswered || _activeShardIndex != index) return;
    setState(() {
      _shardOffsets[index] =
          (_shardOffsets[index] ?? Offset.zero) + details.delta;

      // Update trail
      final trail = _shardTrails[index] ?? [];
      trail.add(_shardOffsets[index]!);
      if (trail.length > 10) trail.removeAt(0);
      _shardTrails[index] = trail;
    });

    // Check for "near gate" haptic feedback
    final currentOffset = _shardOffsets[index] ?? Offset.zero;
    final shardInitialPos = _getShardInitialPosition(
      index,
      (_lastQuest?.options?.length ?? 4),
      _lastConstraints!,
    );
    final currentPos = shardInitialPos + currentOffset;
    if (currentPos.distance < 120.r && currentPos.distance > 100.r) {
      _hapticService.selection();
    }
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    if (_isAnswered || _activeShardIndex != index) return;
    if (_lastConstraints == null) return;

    final isCompact = _lastConstraints!.maxHeight < 580;
    final currentOffset = _shardOffsets[index] ?? Offset.zero;
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
      setState(() {
        _shardOffsets[index] = Offset.zero;
        _shardTrails[index] = [];
        _activeShardIndex = null;
      });
      _hapticService.light();
    }
  }

  void _onShardTapped(int index) {
    if (_isAnswered || _isWarping[index] == true) return;
    setState(() {
      _activeShardIndex = index;
    });
    _hapticService.light();
  }

  void _onWarpGateTapped(VocabularyQuest quest) {
    if (_activeShardIndex == null || _isAnswered || _lastConstraints == null)
      return;
    final index = _activeShardIndex!;
    final options = quest.options ?? [];
    if (index >= options.length) return;

    _warpShard(index, options[index], quest);
  }

  void _warpShard(int index, String text, VocabularyQuest quest) {
    setState(() {
      _isWarping[index] = true;
      _activeShardIndex = null;
    });

    final correct = quest.correctAnswer?.trim().toLowerCase() ?? "";
    final isCorrect = text.trim().toLowerCase() == correct;

    if (isCorrect) {
      _hapticService.selection(); // Subtle feedback for Phase 1
      setState(() {
        _isFirstStagePassed = true;
      });
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = !state.answerStatus.isAnswered && _isAnswered;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isFirstStagePassed = false;
              _initShards(state.currentQuest.options?.length ?? 0);
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'WORD WARP COMPLETE!',
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

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: (state is VocabularyLoaded)
              ? state.isFinalFailure
              : false,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          useScrolling: false,
          onHint: () {
            final options = quest?.options ?? [];
            final correct = quest?.correctAnswer?.toLowerCase() ?? "";
            for (int i = 0; i < options.length; i++) {
              if (options[i].toLowerCase() == correct) {
                setState(() {
                  _shardOffsets[i] =
                      _getShardInitialPosition(
                        i,
                        options.length,
                        _lastConstraints!,
                      ) *
                      -0.2;
                });
                Future.delayed(1.seconds, () {
                  if (mounted && !_isAnswered) {
                    setState(() => _shardOffsets[i] = Offset.zero);
                  }
                });
                break;
              }
            }
          },
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    _lastConstraints = constraints;
                    final screenSize = MediaQuery.of(context).size;
                    final double safeWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : screenSize.width;
                    final double safeHeight = constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : (screenSize.height * 0.6);
                    final isCompact = safeHeight < 580;

                    return SizedBox(
                      width: safeWidth,
                      height: safeHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: CosmicGridPainter(
                                  theme.primaryColor.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ),
                          isCompact
                              ? SizedBox(
                                  width: 140.r,
                                  height: 140.r,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: SynonymWarpGate(
                                      word: quest.word ?? "",
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      onTap: () => _onWarpGateTapped(quest),
                                    ),
                                  ),
                                )
                              : SynonymWarpGate(
                                  word: quest.word ?? "",
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                  onTap: () => _onWarpGateTapped(quest),
                                ),
                          ...List.generate(quest.options?.length ?? 0, (i) {
                            if (_activeShardIndex == i &&
                                _shardTrails[i] != null) {
                              final initialPos = _getShardInitialPosition(
                                i,
                                quest.options!.length,
                                constraints,
                              );
                              final absoluteTrail = _shardTrails[i]!
                                  .map(
                                    (offset) => Offset(
                                      constraints.maxWidth / 2 +
                                          initialPos.dx +
                                          offset.dx,
                                      constraints.maxHeight / 2 +
                                          initialPos.dy +
                                          offset.dy,
                                    ),
                                  )
                                  .toList();

                              return Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: TrailPainter(
                                      absoluteTrail,
                                      theme.primaryColor,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                          ...List.generate(quest.options?.length ?? 0, (i) {
                            return isCompact
                                ? Positioned(
                                    left:
                                        safeWidth / 2 +
                                        _getShardInitialPosition(
                                          i,
                                          quest.options!.length,
                                          constraints,
                                        ).dx +
                                        (_shardOffsets[i] ?? Offset.zero).dx -
                                        45.w,
                                    top:
                                        safeHeight / 2 +
                                        _getShardInitialPosition(
                                          i,
                                          quest.options!.length,
                                          constraints,
                                        ).dy +
                                        (_shardOffsets[i] ?? Offset.zero).dy -
                                        25.h,
                                    child: SizedBox(
                                      width: 90.w,
                                      height: 50.h,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: SizedBox(
                                          width: 120.w,
                                          height: 60.h,
                                          child: SynonymWordShard(
                                            index: i,
                                            text: quest.options![i],
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            initialPos: Offset.zero,
                                            offset: Offset.zero,
                                            isWarping: _isWarping[i] ?? false,
                                            isActive: _activeShardIndex == i,
                                            safeWidth: safeWidth,
                                            safeHeight: safeHeight,
                                            onPanStart: (d) =>
                                                _onShardDragStart(i, d),
                                            onPanUpdate: (d) =>
                                                _onShardDragUpdate(i, d),
                                            onPanEnd: () =>
                                                _onShardDragEnd(i, quest),
                                            onTap: () => _onShardTapped(i),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : SynonymWordShard(
                                    index: i,
                                    text: quest.options![i],
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    initialPos: _getShardInitialPosition(
                                      i,
                                      quest.options!.length,
                                      constraints,
                                    ),
                                    offset: _shardOffsets[i] ?? Offset.zero,
                                    isWarping: _isWarping[i] ?? false,
                                    isActive: _activeShardIndex == i,
                                    safeWidth: safeWidth,
                                    safeHeight: safeHeight,
                                    onPanStart: (d) => _onShardDragStart(i, d),
                                    onPanUpdate: (d) =>
                                        _onShardDragUpdate(i, d),
                                    onPanEnd: () => _onShardDragEnd(i, quest),
                                    onTap: () => _onShardTapped(i),
                                  );
                          }),
                          Positioned(
                            top: isCompact ? 2.h : 10.h,
                            child: isCompact
                                ? SizedBox(
                                    height: 25.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: SynonymInstructionHeader(
                                        color: theme.primaryColor,
                                        instruction:
                                            quest.instruction.isNotEmpty
                                            ? quest.instruction
                                            : "WARP THE SYNONYM SHARD",
                                      ),
                                    ),
                                  )
                                : SynonymInstructionHeader(
                                    color: theme.primaryColor,
                                    instruction: quest.instruction.isNotEmpty
                                        ? quest.instruction
                                        : "WARP THE SYNONYM SHARD",
                                  ),
                          ),
                          if (_isFirstStagePassed && !_isAnswered)
                            DynamicAnagramWrapper(
                              title: 'SPELL THE SYNONYM',
                              subtitle: 'Tap all letters to rebuild the word!',
                              expectedText: quest.correctAnswer ?? '',
                              primaryColor: theme.primaryColor,
                              onConfirmed: () => _submitVerbalEvaluation(true),
                              onFailed: () {},
                              onFailedWithSpelling: (wrongWord) =>
                                  _submitVerbalEvaluation(false),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
