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
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_painters.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_nebula_core.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_option_shard.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_gradient_scale.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isDragPassed = ValueNotifier(false);

  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  final Map<int, ValueNotifier<Offset>> _shardOffsets = {};
  final Map<int, ValueNotifier<bool>> _isFused = {};
  final ValueNotifier<int?> _activeShardIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
  BoxConstraints? _lastConstraints;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isDragPassed.dispose();
    _activeShardIndex.dispose();
    _scrollController.dispose();
    _disposeShardNotifiers();
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

  void _resetQuestState(VocabularyQuest? quest, int index) {
    _lastQuest = quest;
    _lastProcessedIndex = index;
    _isAnswered.value = false;
    _isCorrect.value = null;
    _isDragPassed.value = false;

    _disposeShardNotifiers();

    int optionsCount = quest?.options?.length ?? 0;
    for (int i = 0; i < optionsCount; i++) {
      _shardOffsets[i] = ValueNotifier(Offset.zero);
      _isFused[i] = ValueNotifier(false);
    }

    _activeShardIndex.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetColor = const Color(0xFF00E5FF);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;

          if (isNewQuestion || isRetry) {
            _resetQuestState(state.currentQuest, state.currentIndex);
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
        }
        if (state is VocabularyGameComplete) {
          _showConfetti.value = true;
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

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _isDragPassed,
          ]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is VocabularyLoaded
                  ? state.isFinalFailure
                  : false,
              showConfetti: _showConfetti.value,
              hasStage2: true,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(const NextQuestion()),
              onHint: () => context.read<VocabularyBloc>().add(
                const VocabularyHintUsed(),
              ),
              useScrolling: false,
              disablePadding: true,
              child: quest == null
                  ? const SizedBox.shrink()
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

                                            Center(
                                              child: GestureDetector(
                                                onTap: _onCoreTapped,
                                                child: isCompact
                                                    ? SizedBox(
                                                        width: 140.w,
                                                        height: 140.w,
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: AntonymNebulaCore(
                                                            word: quest.word ?? "",
                                                            color: targetColor,
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
                                                          _activeShardIndex
                                                              .value ==
                                                          i,
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
                                  if (_isDragPassed.value && !_isAnswered.value)
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
                                              quest.explanation!.isNotEmpty) ...[
                                            SizedBox(height: 16.h),
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                                              child: Container(
                                                padding: EdgeInsets.all(16.r),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.lightbulb_outline_rounded, color: theme.primaryColor, size: 20.r),
                                                    SizedBox(width: 12.w),
                                                    Expanded(
                                                      child: Text(
                                                        quest.explanation!,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 14.sp,
                                                          fontWeight: FontWeight.w500,
                                                          color: isDark ? Colors.white70 : Colors.black87,
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
                                          SpeakToConfirmOverlay(
                                            expectedText:
                                                "${quest.word} ${quest.correctAnswer}",
                                            displayText:
                                                "${quest.word?.toUpperCase()}   ↔   ${quest.correctAnswer?.toUpperCase()}",
                                            primaryColor: theme.primaryColor,
                                            onConfirmed: () =>
                                                _submitVerbalEvaluation(true),
                                            onSkipped: () =>
                                                _submitVerbalEvaluation(false),
                                            isPositioned: false,
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

    return Offset(isLeft ? (w * 0.25) : (w * 0.75), yPos);
  }

  void _onShardStart(int index) {
    if (_isAnswered.value || _isDragPassed.value || _isFused[index]?.value == true) return;
    _activeShardIndex.value = index;
    _hapticService.light();
  }

  void _onShardUpdate(int index, DragUpdateDetails details) {
    if (_activeShardIndex.value != index) return;
    if (_shardOffsets[index] != null) {
      _shardOffsets[index]!.value += details.delta;
      final initial = _getInitialPosition(index);
      final currentY = initial.dy + _shardOffsets[index]!.value.dy;
      final maxHeight = _lastConstraints?.maxHeight ?? 600;

      final triggerTop = maxHeight * 0.40;
      final triggerBottom = maxHeight * 0.60;

      if (currentY > triggerTop && currentY < triggerBottom) {
        _hapticService.selection();
      }
    }
  }

  void _onShardEnd(int index) {
    if (_activeShardIndex.value != index || _lastConstraints == null) return;
    final initial = _getInitialPosition(index);
    final offset = _shardOffsets[index]?.value ?? Offset.zero;
    final currentY = initial.dy + offset.dy;

    final maxHeight = _lastConstraints!.maxHeight;
    final bool nearCenter = currentY > maxHeight * 0.35 && currentY < maxHeight * 0.65;

    if (nearCenter) {
      _evaluateShard(index);
    } else {
      if (_shardOffsets[index] != null) {
        _shardOffsets[index]!.value = Offset.zero;
      }
      _activeShardIndex.value = null;
      _hapticService.light();
    }
  }

  void _onShardTapped(int index) {
    if (_isAnswered.value || _isDragPassed.value || _isFused[index]?.value == true) return;
    _activeShardIndex.value = index;
    _hapticService.light();
  }

  void _onCoreTapped() {
    if (_activeShardIndex.value == null ||
        _isAnswered.value ||
        _isDragPassed.value ||
        _lastConstraints == null) {
      return;
    }
    _evaluateShard(_activeShardIndex.value!);
  }

  void _evaluateShard(int index) {
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
    _hapticService.selection();
    if (_isFused[index] != null) {
      _isFused[index]!.value = true;
    }
    _isDragPassed.value = true;
    _activeShardIndex.value = null;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

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

    if (_shardOffsets[index] != null) {
      _shardOffsets[index]!.value = Offset.zero;
    }
    _isAnswered.value = true;
    _isCorrect.value = false;
    _activeShardIndex.value = null;

    context.read<VocabularyBloc>().add(SubmitAnswer(false));
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
    final bool toTop = current.dy < (maxHeight / 2);

    // The pulsars are near the top/bottom edges
    final targetY = toTop ? maxHeight * 0.12 : maxHeight * 0.88;

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
