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
import '../widgets/prefix_suffix_mission_control.dart';
import '../widgets/prefix_suffix_docking_terminal.dart';
import '../widgets/prefix_suffix_root_rover.dart';

class PrefixSuffixScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PrefixSuffixScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prefixSuffix,
  });

  @override
  State<PrefixSuffixScreen> createState() => _PrefixSuffixScreenState();
}

class _PrefixSuffixScreenState extends State<PrefixSuffixScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  Offset _dragOffset = Offset.zero;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onRoverDrag(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onRoverRelease(VocabularyQuest quest) {
    if (_isAnswered) return;
    if (_lastConstraints == null) return;

    final isCompact = _lastConstraints!.maxHeight < 580;
    final options = quest.options ?? [];
    int? dockedIndex;

    // Check collision with terminals - dynamically scale collision radius
    final double collisionDistance = isCompact ? 65.r : 90.r;
    for (int i = 0; i < options.length; i++) {
      final terminalPos = _getTerminalPosition(
        i,
        options.length,
        _lastConstraints!,
      );
      final roverPos = Offset.zero + _dragOffset;

      if ((roverPos - terminalPos).distance < collisionDistance) {
        dockedIndex = i;
        break;
      }
    }

    if (dockedIndex != null) {
      // Visual Snap to terminal
      setState(() {
        _dragOffset = _getTerminalPosition(
          dockedIndex!,
          options.length,
          _lastConstraints!,
        );
      });
      _submitAffix(options[dockedIndex], quest);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
      });
      _hapticService.light();
    }
  }

  void _submitAffix(String option, VocabularyQuest quest) {
    final correctWord = quest.correctAnswer?.toLowerCase() ?? "";
    final cleanOption = option.replaceAll('-', '').trim().toLowerCase();

    bool isCorrect = false;
    // ROBUST CHECK: Handles spelling changes (like Create -> Creation)
    if (option.endsWith('-')) {
      // Prefix (e.g., UN-)
      isCorrect = correctWord.startsWith(cleanOption);
    } else if (option.startsWith('-')) {
      // Suffix (e.g., -NESS)
      isCorrect = correctWord.endsWith(cleanOption);
    } else {
      isCorrect = correctWord.contains(cleanOption);
    }

    if (isCorrect) {
      _soundService.playCorrect();
      _hapticService.success();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _soundService.playWrong();
      _hapticService.error();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  BoxConstraints? _lastConstraints;

  Offset _getTerminalPosition(
    int index,
    int total,
    BoxConstraints constraints,
  ) {
    // FALLBACK: If constraints are infinite (common in ScrollViews), use screen size
    final screenSize = MediaQuery.of(context).size;
    final double safeMaxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : screenSize.width;
    final double safeMaxHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : (screenSize.height * 0.6);
    final isCompact = safeMaxHeight < 580;

    // Dynamic Responsive Positioning (Diamond/Corner Grid)
    double hDist = (safeMaxWidth - 120.w) / 2;
    double vDist = (safeMaxHeight - (isCompact ? 130.h : 180.h)) / 2;

    // Use a smaller radius if the screen is tiny
    hDist = hDist.clamp(isCompact ? 60.w : 80.w, 140.w);
    vDist = vDist.clamp(isCompact ? 70.h : 100.h, 160.h);

    switch (index) {
      case 0:
        return Offset(-hDist, -vDist); // Top Left
      case 1:
        return Offset(hDist, -vDist); // Top Right
      case 2:
        return Offset(-hDist, vDist); // Bottom Left
      case 3:
        return Offset(hDist, vDist); // Bottom Right
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
              _dragOffset = Offset.zero;
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
            title: 'LEXICAL MASTER!',
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
              final opt = options[i].replaceAll('-', '').trim().toLowerCase();
              if (correct.contains(opt)) {
                setState(
                  () => _dragOffset =
                      _getTerminalPosition(
                        i,
                        options.length,
                        _lastConstraints!,
                      ) *
                      0.4,
                );
                Future.delayed(1.seconds, () {
                  if (mounted && !_isAnswered) {
                    setState(() => _dragOffset = Offset.zero);
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
                          Positioned(
                            top: 20.h,
                            child: PrefixSuffixMissionControl(
                              primaryColor: theme.primaryColor,
                              instruction: quest.hint ?? quest.instruction,
                            )
                                .animate(target: _isAnswered ? 1 : 0)
                                .fadeOut(duration: 400.ms)
                                .slideY(
                                  begin: 0,
                                  end: -1.5,
                                  duration: 400.ms,
                                  curve: Curves.easeIn,
                                ),
                          ),

                          // Docking Terminals (Options)
                          ...List.generate(
                            quest.options?.length ?? 0,
                            (i) => PrefixSuffixDockingTerminal(
                              index: i,
                              text: quest.options![i],
                              primaryColor: theme.primaryColor,
                              isDark: isDark,
                              position: _getTerminalPosition(
                                i,
                                quest.options!.length,
                                constraints,
                              ),
                              parentWidth: safeWidth,
                              parentHeight: safeHeight,
                            ),
                          ),

                          // The Root Rover (Central Draggable)
                          isCompact
                              ? SizedBox(
                                  width: 100.w,
                                  height: 100.h,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: PrefixSuffixRootRover(
                                      rootWord: quest.rootWord ?? "???",
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      dragOffset: _dragOffset,
                                      onPanUpdate: _onRoverDrag,
                                      onPanEnd: (_) => _onRoverRelease(quest),
                                    ),
                                  ),
                                )
                              : PrefixSuffixRootRover(
                                  rootWord: quest.rootWord ?? "???",
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  dragOffset: _dragOffset,
                                  onPanUpdate: _onRoverDrag,
                                  onPanEnd: (_) => _onRoverRelease(quest),
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

