import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_painters.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_warp_gate.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_word_shard.dart';

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

    final currentOffset = _shardOffsets[index] ?? Offset.zero;
    final options = quest.options ?? [];
    final selectedText = options[index];

    final shardInitialPos = _getShardInitialPosition(
      index,
      options.length,
      _lastConstraints!,
    );
    final currentPos = shardInitialPos + currentOffset;

    if (currentPos.distance < 100.r) {
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

  void _warpShard(int index, String text, VocabularyQuest quest) {
    setState(() {
      _isWarping[index] = true;
      _activeShardIndex = null;
    });

    final correct = quest.correctAnswer?.trim().toLowerCase() ?? "";
    final isCorrect = text.trim().toLowerCase() == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
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

    double hDist = (safeWidth - 100.w) / 2;
    double vDist = (safeHeight - 120.h) / 2;

    hDist = hDist.clamp(90.w, 130.w);
    vDist = vDist.clamp(120.h, 140.h);

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
          final isRetry = state.lastAnswerCorrect == null && _isAnswered;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _initShards(state.currentQuest.options?.length ?? 0);
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
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
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

        if (state is VocabularyLoading || (state is! VocabularyGameComplete && state is! VocabularyLoaded && state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
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
                  _shardOffsets[i] = _getShardInitialPosition(
                    i,
                    options.length,
                    _lastConstraints!,
                  ) * -0.2;
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
                          SynonymWarpGate(
                            word: quest.word ?? "",
                            color: theme.primaryColor,
                            isDark: isDark,
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
                            return SynonymWordShard(
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
                              onPanUpdate: (d) => _onShardDragUpdate(i, d),
                              onPanEnd: () => _onShardDragEnd(i, quest),
                            );
                          }),
                          Positioned(
                            top: 10.h,
                            child: _buildInstruction(theme.primaryColor),
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

  Widget _buildInstruction(Color color) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cyclone_rounded, size: 16.r, color: color),
              SizedBox(width: 10.w),
              Text(
                "WARP THE SYNONYM SHARD",
                style: GoogleFonts.shareTechMono(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 3.seconds,
          color: Colors.white.withValues(alpha: 0.3),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 2.seconds,
          curve: Curves.easeInOut,
        );
  }

}

