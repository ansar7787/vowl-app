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
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/morph_injection_rail.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/reaction_core.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/instruction_panel.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/controllers/word_formation_controller.dart';

class WordFormationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordFormationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordFormation,
  });

  @override
  State<WordFormationScreen> createState() => _WordFormationScreenState();
}

class _WordFormationScreenState extends State<WordFormationScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late final WordFormationController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToStage2 = false;

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller.isFirstStagePassed &&
        !_controller.isAnswered &&
        !_hasScrolledToStage2) {
      _hasScrolledToStage2 = true;
      Future.delayed(const Duration(milliseconds: 400), _scrollToBottom);
    } else if (!_controller.isFirstStagePassed) {
      _hasScrolledToStage2 = false;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WordFormationController(
      hapticService: _hapticService,
      soundService: _soundService,
      onSubmitAnswer: (isCorrect) {
        if (mounted) {
          context.read<VocabularyBloc>().add(SubmitAnswer(isCorrect));
        }
      },
    );

    _controller.addListener(_onControllerUpdate);

    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion =
              state.currentIndex != _controller.lastProcessedIndex;
          final isRetry =
              !state.answerStatus.isAnswered && _controller.isAnswered;

          if (isNewQuestion || isRetry) {
            _controller.reset(state.currentQuest, state.currentIndex);
          } else if (state.answerStatus.isAnswered && !_controller.isAnswered) {
            _controller.isAnswered = true;
            _controller.isCorrect = state.answerStatus.asBoolOrNull;
          }
        }
        if (state is VocabularyGameComplete) {
          final xp = state.xpEarned;
          final coins = state.coinsEarned;
          _controller.completeGame();
          if (!context.mounted) return;
          GameDialogHelper.showCompletion(
            context,
            xp: xp,
            coins: coins,
            title: 'WORD ARCHITECT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        final isDark = Theme.of(context).brightness == Brightness.dark;

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _controller.lastQuest;
        final options = quest?.options ?? [];
        final root = quest?.rootWord ?? quest?.word ?? "";

        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            // Use hovering suffix if dragging, otherwise use active selection
            final displaySuffixIndex =
                _controller.hoveringSuffixIndex ??
                _controller.activeSuffixIndex;
            final activeSuffix =
                (displaySuffixIndex != null &&
                    options.isNotEmpty &&
                    displaySuffixIndex < options.length)
                ? options[displaySuffixIndex]
                : null;

            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _controller.isAnswered,
              isCorrect: _controller.isCorrect,
              showConfetti: _controller.showConfetti,
              hasStage2: true,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(NextQuestion()),
              disablePadding: true,
              onHint: () {
                // Find correct suffix index
                final correct = quest?.correctAnswer ?? "";

                // Speak the target word as a powerful audio hint
                if (correct.isNotEmpty) {
                  di.sl<TtsService>().speak(correct);
                }

                final options = quest?.options ?? [];
                int? correctIdx;
                for (int i = 0; i < options.length; i++) {
                  final cleanS = options[i]
                      .replaceAll('-', '')
                      .trim()
                      .toLowerCase();
                  if (correct.toLowerCase().endsWith(cleanS) ||
                      correct.toLowerCase().startsWith(cleanS)) {
                    correctIdx = i;
                    break;
                  }
                }
                if (correctIdx != null) {
                  _controller.setHoveringIndex(correctIdx);
                  // Auto-reset after a short delay if they don't drag
                  Future.delayed(2.seconds, () {
                    if (mounted && !_controller.isAnswered) {
                      _controller.setHoveringIndex(null);
                    }
                  });
                }
              },
              child: quest == null
                  ? const SizedBox()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Prevent the layout from crushing when the keyboard opens
                        final maxHeight = math.max(constraints.maxHeight, 600.h);
                        final isCompact = maxHeight < 580;

                        // Spacing calculations
                        final double estimatedContentHeight =
                            (isCompact ? 60.h : 80.h) +
                            (isCompact ? 120.h : 140.h) +
                            (options.length * (isCompact ? 46.h : 72.h)) +
                            20.h;
                        final remainingHeight =
                            maxHeight - estimatedContentHeight;

                        final double gapUnit = remainingHeight > 0
                            ? remainingHeight / 5
                            : 0;
                        final double gapTop = remainingHeight > 0
                            ? (gapUnit * 1).clamp(6.0, 20.0)
                            : 6.0;
                        final double gapMiddle = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(10.0, 25.0)
                            : 10.0;
                        final double gapBottom = remainingHeight > 0
                            ? (gapUnit * 2).clamp(12.0, 30.0)
                            : 12.0;

                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(
                            alpha: 0.5,
                          ),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: maxHeight,
                                      ),
                                      child: IgnorePointer(
                                        ignoring:
                                            _controller.isFirstStagePassed,
                                        child: Column(
                                          key: ValueKey(quest.id),
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            SizedBox(height: gapTop + 32.h),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24.w,
                                              ),
                                              child:
                                                  InstructionPanel(
                                                        color:
                                                            theme.primaryColor,
                                                        quest: quest,
                                                      )
                                                      .animate()
                                                      .fadeIn(duration: 500.ms)
                                                      .slideY(
                                                        begin: -0.5,
                                                        end: 0,
                                                        duration: 500.ms,
                                                        curve:
                                                            Curves.easeOutBack,
                                                      ),
                                            ),
                                            SizedBox(height: gapMiddle * 0.4),

                                            // Reaction Core
                                            (isCompact
                                                    ? SizedBox(
                                                        height: 120.h,
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: SizedBox(
                                                            width: constraints
                                                                .maxWidth,
                                                            child: ReactionCore(
                                                              quest: quest,
                                                              root: root,
                                                              suffix:
                                                                  activeSuffix,
                                                              color: theme
                                                                  .primaryColor,
                                                              isDark: isDark,
                                                              controller:
                                                                  _controller,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : ReactionCore(
                                                        quest: quest,
                                                        root: root,
                                                        suffix: activeSuffix,
                                                        color:
                                                            theme.primaryColor,
                                                        isDark: isDark,
                                                        controller: _controller,
                                                      ))
                                                .animate()
                                                .scale(
                                                  begin: const Offset(0.8, 0.8),
                                                  end: const Offset(1.0, 1.0),
                                                  duration: 600.ms,
                                                  curve: Curves.easeOutBack,
                                                )
                                                .fadeIn(duration: 600.ms),

                                            SizedBox(height: gapMiddle),

                                            // Injection Rails
                                            _buildInjectionRails(
                                              options,
                                              root,
                                              quest.correctAnswer ?? "",
                                              theme.primaryColor,
                                              isDark,
                                              isCompact,
                                            ),
                                            SizedBox(
                                              height: gapBottom,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_controller.isFirstStagePassed &&
                                      !_controller.isAnswered)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          bottom: 24.h + MediaQuery.viewInsetsOf(context).bottom,
                                        ),
                                        child: TypeToConfirmOverlay(
                                          expectedText:
                                              quest.correctAnswer ?? '',
                                          displayText:
                                              "Type the correct form:\n${quest.correctAnswer?.toUpperCase()}",
                                          primaryColor: theme.primaryColor,
                                          onConfirmed: () =>
                                              _controller.submitFinalAnswer(
                                                true,
                                              ),
                                          onSkipped: () =>
                                              _controller.submitFinalAnswer(
                                                false,
                                              ),
                                          onBypassed: () =>
                                              _controller.submitFinalAnswer(
                                                true,
                                              ),
                                          isPositioned: false,
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

  Widget _buildInjectionRails(
    List<String> options,
    String root,
    String correct,
    Color color,
    bool isDark,
    bool isCompact,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: options.asMap().entries.map((entry) {
          return Padding(
                padding: EdgeInsets.only(bottom: isCompact ? 6.h : 12.h),
                child: SizedBox(
                  width: 1.sw,
                  height: isCompact ? 50.h : 60.h,
                  child: MorphInjectionRail(
                    index: entry.key,
                    suffix: entry.value,
                    color: color,
                    isDark: isDark,
                    isBlocked:
                        _controller.isAnswered ||
                        _controller.isFirstStagePassed,
                    onMorph: (suffix) {
                      _controller.submitMorph(
                        suffix,
                        root,
                        correct,
                        entry.key,
                      );
                    },
                    onHover: (index) {
                      if (!_controller.isAnswered &&
                          !_controller.isFirstStagePassed) {
                        _controller.setHoveringIndex(index);
                      }
                    },
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: (entry.key * 100).ms)
              .slideX(
                begin: 0.5,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic,
                delay: (entry.key * 100).ms,
              );
        }).toList(),
      ),
    );
  }
}
