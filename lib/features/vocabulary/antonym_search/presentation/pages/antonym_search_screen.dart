import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_painters.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_pulsar.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_nebula_core.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_option_shard.dart';
import 'package:vowl/core/presentation/game_mechanics/dynamic_anagram_wrapper.dart';

class AntonymSearchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AntonymSearchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.antonymSearch,
  });
  @override
  State<AntonymSearchScreen> createState() => _AntonymSearchScreenState();
}

class _AntonymSearchScreenState extends State<AntonymSearchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isFirstStagePassed = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  bool _targetIsPositive = true;

  final Map<int, Offset> _shardOffsets = {};
  final Map<int, bool> _isFused = {};
  int? _activeShardIndex;
  BoxConstraints? _lastConstraints;

  @override
  void initState() {
    super.initState();
    _targetIsPositive = math.Random().nextBool();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetColor = _targetIsPositive
        ? const Color(0xFF00E5FF)
        : const Color(0xFFFF4D00);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isFirstStagePassed = false;
              _targetIsPositive = math.Random().nextBool();
              _isFused.clear();
              _shardOffsets.clear();
              _activeShardIndex = null;
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
            title: 'POLARITY MASTER!',
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
          isFinalFailure: state is VocabularyLoaded
              ? state.isFinalFailure
              : false,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _lastConstraints = constraints;
                    final maxHeight = constraints.maxHeight;
                    final isCompact = maxHeight < 580;
      
                    return Column(
                      children: [
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                  // Magnetic Flux Background
                  Positioned.fill(
                    child: CustomPaint(painter: FluxGridPainter(isDark)),
                  ),

                  AntonymPulsar(
                    isTop: true,
                    targetIsPositive: _targetIsPositive,
                    onTap: () => _onPulsarTapped(true),
                  ),
                  AntonymPulsar(
                    isTop: false,
                    targetIsPositive: _targetIsPositive,
                    onTap: () => _onPulsarTapped(false),
                  ),

                  // Instruction removed: It was overlapping the top Pulsar,
                  // and AntonymNebulaCore already says "DRAG TO OPPOSITE"
                  Center(
                    child: isCompact
                        ? SizedBox(
                            width: 140.w,
                            height: 140.w,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AntonymNebulaCore(
                                word: quest?.word ?? "",
                                color: targetColor,
                                isDark: isDark,
                                targetIsPositive: _targetIsPositive,
                              ),
                            ),
                          )
                        : AntonymNebulaCore(
                            word: quest?.word ?? "",
                            color: targetColor,
                            isDark: isDark,
                            targetIsPositive: _targetIsPositive,
                          ),
                  ),

                  ...List.generate(
                    quest?.options?.length ?? 0,
                    (i) => AntonymOptionShard(
                      index: i,
                      text: quest!.options![i],
                      color: theme.primaryColor,
                      isDark: isDark,
                      initialPos: _getInitialPosition(i),
                      offset: _shardOffsets[i] ?? Offset.zero,
                      isDragging: _activeShardIndex == i,
                      isFused: _isFused[i] ?? false,
                      onPanStart: () => _onShardStart(i),
                      onPanUpdate: (d) => _onShardUpdate(i, d),
                      onPanEnd: () => _onShardEnd(i),
                      onTap: () => _onShardTapped(i),
                    ),
                  ),

                  if (_activeShardIndex != null)
                    _buildPlasmaThunder(targetColor, isCompact),
                            ],
                          ),
                        ),
                        if (_isFirstStagePassed && !_isAnswered)
                          DynamicAnagramWrapper(
                            title: 'SPELL THE ANTONYM',
                            subtitle: 'Tap all letters to rebuild the word!',
                            expectedText: _lastQuest!.correctAnswer ?? '',
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitVerbalEvaluation(true),
                            onFailed: () {},
                            onFailedWithSpelling: (wrongWord) =>
                                _submitVerbalEvaluation(false),
                            isPositioned: false,
                          ),
                        SizedBox(height: (_isAnswered || _isFirstStagePassed) ? 160.h : 60.h),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Offset _getInitialPosition(int index) {
    if (_lastConstraints == null) return Offset.zero;
    final w = _lastConstraints!.maxWidth;
    final h = _lastConstraints!.maxHeight;
    final isCompact = h < 580;
    final isLeft = index % 2 == 0;
    final int total = _lastQuest?.options?.length ?? 4;
    final int halfTotal = (total / 2).ceil();
    final bool isBottomHalf = index >= halfTotal;

    double yPos;
    if (total <= 4) {
      // 2 at top, 2 at bottom
      yPos = isBottomHalf
          ? (h * (isCompact ? 0.71 : 0.75))
          : (h * (isCompact ? 0.29 : 0.25));
    } else {
      // Standard grid for 6 or 8 cards
      if (index < 2) {
        yPos = h * (isCompact ? 0.22 : 0.18);
      } else if (index < 4) {
        yPos = h * (isCompact ? 0.35 : 0.32);
      } else if (index < 6) {
        yPos = h * (isCompact ? 0.65 : 0.68);
      } else {
        yPos = h * (isCompact ? 0.78 : 0.82);
      }
    }

    return Offset(isLeft ? (w * 0.25) : (w * 0.75), yPos);
  }

  void _onShardStart(int index) {
    if (_isAnswered || _isFused[index] == true) return;
    setState(() => _activeShardIndex = index);
    _hapticService.light();
  }

  void _onShardUpdate(int index, DragUpdateDetails details) {
    if (_activeShardIndex != index) return;
    setState(
      () => _shardOffsets[index] =
          (_shardOffsets[index] ?? Offset.zero) + details.delta,
    );
    final initial = _getInitialPosition(index);
    final currentY = initial.dy + (_shardOffsets[index]?.dy ?? 0);
    final isCompact = (_lastConstraints?.maxHeight ?? 600) < 580;
    final triggerTop = isCompact ? 100.h : 120.h;
    final triggerBottom =
        (_lastConstraints?.maxHeight ?? 600) - (isCompact ? 100.h : 120.h);
    if (currentY < triggerTop || currentY > triggerBottom) {
      _hapticService.selection();
    }
  }

  void _onShardEnd(int index) {
    if (_activeShardIndex != index || _lastConstraints == null) return;
    final initial = _getInitialPosition(index);
    final offset = _shardOffsets[index] ?? Offset.zero;
    final currentY = initial.dy + offset.dy;

    // Use actual constraints for reliable detection
    final maxHeight = _lastConstraints!.maxHeight;
    final isCompact = maxHeight < 580;
    final bool nearTop = currentY < (isCompact ? 100.h : 130.h);
    final bool nearBottom =
        currentY > (maxHeight - (isCompact ? 100.h : 130.h));

    if (nearTop || nearBottom) {
      _evaluateShard(index, nearTop);
    } else {
      setState(() {
        _shardOffsets[index] = Offset.zero;
        _activeShardIndex = null;
      });
      _hapticService.light();
    }
  }

  void _onShardTapped(int index) {
    if (_isAnswered || _isFused[index] == true) return;
    setState(() => _activeShardIndex = index);
    _hapticService.light();
  }

  void _onPulsarTapped(bool isTop) {
    if (_activeShardIndex == null || _isAnswered || _lastConstraints == null) {
      return;
    }
    _evaluateShard(_activeShardIndex!, isTop);
  }

  void _evaluateShard(int index, bool toTop) {
    final bool toPositive = toTop;
    final bool isOpposite =
        (toPositive && !_targetIsPositive) ||
        (!toPositive && _targetIsPositive);
    final bool isAntonym =
        _lastQuest!.options![index].trim().toLowerCase() ==
        _lastQuest!.correctAnswer?.trim().toLowerCase();

    if (isAntonym && isOpposite) {
      _onSuccess(index);
    } else {
      _onFailure(index);
    }
  }

  void _onSuccess(int index) {
    _hapticService.selection(); // Subtle feedback for Phase 1
    setState(() {
      _isFused[index] = true;
      _isFirstStagePassed = true;
      _activeShardIndex = null;
    });
    // Wait for Phase 2
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

  void _onFailure(int index) {
    _hapticService.error();
    _soundService.playWrong();
    setState(() {
      _shardOffsets[index] = Offset.zero;
      _isAnswered = true;
      _isCorrect = false;
      _activeShardIndex = null;
    });
    context.read<VocabularyBloc>().add(SubmitAnswer(false));
  }

  Widget _buildPlasmaThunder(Color color, bool isCompact) {
    if (_activeShardIndex == null || _lastConstraints == null) {
      return const SizedBox();
    }
    final initial = _getInitialPosition(_activeShardIndex!);
    final offset = _shardOffsets[_activeShardIndex!] ?? Offset.zero;
    final current = initial + offset;
    final maxHeight = _lastConstraints!.maxHeight;
    final bool toTop = current.dy < (maxHeight / 2);
    final targetY = toTop
        ? (isCompact ? 70.h : 90.h)
        : (maxHeight - (isCompact ? 70.h : 90.h));

    return IgnorePointer(
      child: CustomPaint(
        painter: PlasmaArcPainter(
          current,
          Offset(_lastConstraints!.maxWidth / 2, targetY),
          toTop ? const Color(0xFF00E5FF) : const Color(0xFFFF4D00),
        ),
      ),
    );
  }
}
