import 'dart:async';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';

import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/morph_injection_rail.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/reaction_core.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/instruction_panel.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/controllers/word_formation_controller.dart';

/// Interactive word formation screen where learners slide morphological affixes into root word reaction cores.
class WordFormationScreen extends StatefulWidget {
  /// The active curriculum difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Creates a [WordFormationScreen] instance.
  const WordFormationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordFormation,
  });

  @override
  State<WordFormationScreen> createState() => _WordFormationScreenState();
}

class _WordFormationScreenState extends State<WordFormationScreen>
    with
        GameScreenMixin<WordFormationScreen>,
        VocabularyGameScreenMixin<WordFormationScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late final WordFormationController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToStage2 = false;
  Timer? _scrollTimer;
  Timer? _hintTimer;

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller.isFirstStagePassed &&
        !_controller.isAnswered &&
        !_hasScrolledToStage2) {
      _hasScrolledToStage2 = true;
      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 400), _scrollToBottom);
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
      hapticService: hapticService,
      soundService: soundService,
      onSubmitAnswer: (isCorrect, {quest, userAnswer}) {
        if (mounted) {
          if (isCorrect) {
            submitCorrectAnswer();
          } else {
            final q = quest ?? _controller.lastQuest;
            if (q != null) {
              submitWrongAnswer(quest: q, userAnswer: userAnswer);
            } else {
              submitWrongAnswer(quest: quest!, userAnswer: '');
            }
          }
        }
      },
    );

    _controller.addListener(_onControllerUpdate);

    initVocabularyGame();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _hintTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _scrollController.dispose();
    _controller.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    final state = context.read<VocabularyBloc>().state;
    if (state is VocabularyLoaded && state.currentQuestOrNull != null) {
      _controller.reset(state.currentQuestOrNull!, state.currentIndex);
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
        if (state is VocabularyLoaded && state.currentQuestOrNull != null) {
          if (_controller.lastQuest != state.currentQuestOrNull ||
              _controller.lastProcessedIndex != state.currentIndex) {
            _controller.reset(state.currentQuestOrNull!, state.currentIndex);
          }
        }

        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

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
                  _hintTimer?.cancel();
                  _hintTimer = Timer(2.seconds, () {
                    if (mounted && !_controller.isAnswered) {
                      _controller.setHoveringIndex(null);
                    }
                  });
                }
              },
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Prevent the layout from crushing when the keyboard opens
                        final maxHeight = math.max(
                          constraints.maxHeight,
                          600.h,
                        );
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

                        final instructionWidget = InstructionPanel(
                          color: theme.primaryColor,
                          quest: quest,
                        );

                        final reactionCoreWidget = ReactionCore(
                          quest: quest,
                          root: root,
                          suffix: activeSuffix,
                          color: theme.primaryColor,
                          isDark: isDark,
                          controller: _controller,
                        );

                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
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
                                    ignoring: _controller.isFirstStagePassed,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                      ),
                                      child: Column(
                                        key: ValueKey(quest.id),
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          SizedBox(height: gapTop + 16.h),
                                          reduceMotion
                                              ? instructionWidget
                                              : instructionWidget
                                                  .animate()
                                                  .fadeIn(duration: 400.ms)
                                                  .slideY(
                                                    begin: -0.2,
                                                    end: 0,
                                                    duration: 400.ms,
                                                    curve: Curves.easeOutCubic,
                                                  ),
                                          SizedBox(height: (gapMiddle * 0.5).clamp(8.0, 16.0)),

                                          // Word Formation Hub Card
                                          reactionCoreWidget,

                                          SizedBox(height: (gapMiddle * 0.8).clamp(10.0, 20.0)),

                                          // Affix Option Rails
                                          _buildInjectionRails(
                                            options,
                                            root,
                                            quest.correctAnswer ?? "",
                                            theme.primaryColor,
                                            isDark,
                                            isCompact,
                                            reduceMotion,
                                          ),
                                          SizedBox(height: gapBottom),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_controller.isFirstStagePassed &&
                                  !_controller.isAnswered)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 20.w,
                                      right: 20.w,
                                      bottom:
                                          24.h +
                                          MediaQuery.viewInsetsOf(
                                            context,
                                          ).bottom,
                                    ),
                                    child: TypeToConfirmOverlay(
                                      expectedText: quest.correctAnswer ?? '',
                                      displayText:
                                          quest.correctAnswer?.toUpperCase(),
                                      primaryColor: theme.primaryColor,
                                      displayFontSize: 22.sp,
                                      displayFontWeight: FontWeight.w700,
                                      onConfirmed: () =>
                                          _controller.submitFinalAnswer(true),
                                      onSkipped: () =>
                                          _controller.submitFinalAnswer(false),
                                      onBypassed: () =>
                                          _controller.submitFinalAnswer(true),
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
    bool reduceMotion,
  ) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final railPadding = Padding(
          padding: EdgeInsets.only(bottom: isCompact ? 6.h : 10.h),
          child: SizedBox(
            width: double.infinity,
            height: isCompact ? 48.h : 54.h,
            child: MorphInjectionRail(
              index: entry.key,
              suffix: entry.value,
              color: color,
              isDark: isDark,
              isBlocked:
                  _controller.isAnswered ||
                  _controller.isFirstStagePassed,
              isPrefix: entry.value.trim().endsWith('-') ||
                  (!entry.value.trim().startsWith('-') &&
                      correct.toLowerCase().startsWith(
                            entry.value
                                .replaceAll('-', '')
                                .trim()
                                .toLowerCase(),
                          )),
              onMorph: (suffix) {
                _controller.submitMorph(suffix, root, correct, entry.key);
              },
              onHover: (index) {
                if (!_controller.isAnswered &&
                    !_controller.isFirstStagePassed) {
                  _controller.setHoveringIndex(index);
                }
              },
            ),
          ),
        );

        if (reduceMotion) {
          return railPadding;
        }

        return railPadding
            .animate()
            .fadeIn(duration: 400.ms, delay: (entry.key * 80).ms)
            .slideX(
              begin: 0.2,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
              delay: (entry.key * 80).ms,
            );
      }).toList(),
    );
  }
}
