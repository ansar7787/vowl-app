import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
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
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocation_anchor_bubble.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocation_option_bubble.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocations_wrong_pairs.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/context_sentence_builder.dart';

class CollocationsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CollocationsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.collocations,
  });

  @override
  State<CollocationsScreen> createState() => _CollocationsScreenState();
}

class _CollocationsScreenState extends State<CollocationsScreen>
    with
        TickerProviderStateMixin,
        GameScreenMixin<CollocationsScreen>,
        VocabularyGameScreenMixin<CollocationsScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<bool> _isDragPassed = ValueNotifier(false);
  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  VocabularyQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  @override
  void dispose() {
    _isDragPassed.dispose();
    _selectedOption.dispose();
    _scrollController.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  void _submitAnswer(String selected, String correct) {
    if (isAnsweredNotifier.value ||
        _isDragPassed.value ||
        _selectedOption.value != null) {
      return;
    }

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    _selectedOption.value = selected;

    if (isCorrect) {
      hapticService.selection();
      _isDragPassed.value = true;

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      hapticService.error();
      soundService.playWrong();
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  String? _getFormattedExampleSentence(VocabularyQuest quest) {
    if (quest.contextSentence == null || quest.contextSentence!.isEmpty) {
      return null;
    }

    final sentence = quest.contextSentence!;
    final word = quest.word ?? "";
    final answer = quest.correctAnswer ?? "";

    // Determine which part of the collocation is missing in the sentence
    final replacementWord = sentence.contains(answer) ? word : answer;

    return sentence.replaceAll('__', replacementWord);
  }

  void _submitFinalAnswer(bool nailedIt) {
    if (isAnsweredNotifier.value && isCorrectNotifier.value != null) return;

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

  @override
  void onQuestionReset() {
    _isDragPassed.value = false;

    _selectedOption.value = null;
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
            _isDragPassed,
            _selectedOption,
          ]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              hasStage2: true,
              onContinue: () {
                final currentState = context.read<VocabularyBloc>().state;
                if (currentState is VocabularyLoaded &&
                    !currentState.isFinalFailure &&
                    isCorrectNotifier.value == false) {
                  isAnsweredNotifier.value = false;
                  isCorrectNotifier.value = null;
                  _isDragPassed.value = false;
                  _selectedOption.value = null;
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                } else {
                  context.read<VocabularyBloc>().add(const NextQuestion());
                }
              },
              onHint: () => context.read<VocabularyBloc>().add(
                const VocabularyHintUsed(),
              ),
              customHintText: quest?.hint,
              useScrolling: false,
              disablePadding: true,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 580;

                        final double estimatedContentHeight =
                            20.h +
                            40.h +
                            (isCompact ? 80.h : 110.h) +
                            (isCompact ? 100.h : 180.h) +
                            20.h;
                        final remainingHeight =
                            maxHeight - estimatedContentHeight;

                        final double gapUnit = remainingHeight > 0
                            ? remainingHeight / 6
                            : 0;
                        final double gapTop = remainingHeight > 0
                            ? (gapUnit * 1).clamp(6.0, 16.0)
                            : 6.0;
                        final double gapInstruction = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(10.0, 30.0)
                            : 10.0;
                        final double gapAnchor = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(10.0, 40.0)
                            : 10.0;
                        final double gapBottom = remainingHeight > 0
                            ? (gapUnit * 2).clamp(12.0, 60.0)
                            : 12.0;

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
                                    child: IgnorePointer(
                                      ignoring: _isDragPassed.value,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: maxHeight,
                                        ),
                                        child: Column(
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: gapTop),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 20.w,
                                                          ),
                                                      child: _buildInstruction(
                                                        theme.primaryColor,
                                                        isDark,
                                                        InstructionHelper.getInstruction(
                                                          quest,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: gapInstruction,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 20.w,
                                                          ),
                                                      child: Semantics(
                                                        label:
                                                            'Drop target for ${quest.word ?? ""}. Drag a matching word here to complete the pair.',
                                                        child: DragTarget<String>(
                                                          onWillAcceptWithDetails:
                                                              (details) {
                                                                hapticService
                                                                    .selection();
                                                                return !isAnsweredNotifier
                                                                        .value &&
                                                                    !_isDragPassed
                                                                        .value;
                                                              },
                                                          onAcceptWithDetails:
                                                              (details) {
                                                                _submitAnswer(
                                                                  details.data,
                                                                  quest.correctAnswer ??
                                                                      "",
                                                                );
                                                              },
                                                          builder:
                                                              (
                                                                context,
                                                                candidateData,
                                                                rejectedData,
                                                              ) {
                                                                bool isHovered =
                                                                    candidateData
                                                                        .isNotEmpty;
                                                                return AnimatedScale(
                                                                  scale:
                                                                      isHovered
                                                                      ? 1.05
                                                                      : 1.0,
                                                                  duration:
                                                                      200.ms,
                                                                  curve: Curves
                                                                      .easeOutBack,
                                                                  child: AnimatedContainer(
                                                                    duration:
                                                                        200.ms,
                                                                    decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            40.r,
                                                                          ),
                                                                      boxShadow:
                                                                          isHovered
                                                                          ? [
                                                                              BoxShadow(
                                                                                color: theme.primaryColor.withValues(
                                                                                  alpha: 0.8,
                                                                                ),
                                                                                blurRadius: 40,
                                                                                spreadRadius: 10,
                                                                              ),
                                                                            ]
                                                                          : [],
                                                                    ),
                                                                    child: CollocationAnchorBubble(
                                                                      text:
                                                                          _isDragPassed
                                                                              .value
                                                                          ? '${quest.word ?? ""} ${quest.correctAnswer ?? ""}'
                                                                          : (quest.word ??
                                                                                ""),
                                                                      color: theme
                                                                          .primaryColor,
                                                                      isDark:
                                                                          isDark,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: gapAnchor),
                                                    isCompact
                                                        ? SizedBox(
                                                            height: 100.h,
                                                            child: FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: SizedBox(
                                                                width: constraints
                                                                    .maxWidth,
                                                                child: _buildOptionsWrap(
                                                                  quest,
                                                                  theme
                                                                      .primaryColor,
                                                                  isDark,
                                                                  state
                                                                          is VocabularyLoaded
                                                                      ? state
                                                                            .isFinalFailure
                                                                      : false,
                                                                  isCompact,
                                                                  state
                                                                          is VocabularyLoaded
                                                                      ? state
                                                                            .hintUsed
                                                                      : false,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : _buildOptionsWrap(
                                                            quest,
                                                            theme.primaryColor,
                                                            isDark,
                                                            state
                                                                    is VocabularyLoaded
                                                                ? state
                                                                      .isFinalFailure
                                                                : false,
                                                            isCompact,
                                                            state
                                                                    is VocabularyLoaded
                                                                ? state.hintUsed
                                                                : false,
                                                          ),
                                                    SizedBox(height: gapBottom),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isDragPassed.value &&
                                      (!isAnsweredNotifier.value ||
                                          isCorrectNotifier.value == null))
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                        ),
                                        child: Column(
                                          children: [
                                            if (quest.wrongCollocations !=
                                                    null &&
                                                quest
                                                    .wrongCollocations!
                                                    .isNotEmpty) ...[
                                              Builder(
                                                builder: (context) {
                                                  final correctPair =
                                                      '${quest.word} ${quest.correctAnswer}'
                                                          .toLowerCase()
                                                          .trim();
                                                  final filteredWrongPairs = quest
                                                      .wrongCollocations!
                                                      .where(
                                                        (w) =>
                                                            w
                                                                .toLowerCase()
                                                                .trim() !=
                                                            correctPair,
                                                      )
                                                      .toList();

                                                  if (filteredWrongPairs
                                                      .isEmpty) {
                                                    return const SizedBox.shrink();
                                                  }

                                                  return Column(
                                                    children: [
                                                      CollocationsWrongPairs(
                                                        wrongCollocations:
                                                            filteredWrongPairs,
                                                        color:
                                                            theme.primaryColor,
                                                      ),
                                                      SizedBox(height: 10.h),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (_isDragPassed.value &&
                                      (!isAnsweredNotifier.value ||
                                          isCorrectNotifier.value == null))
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 20.h,
                                        ),
                                        child: ContextSentenceBuilder(
                                          targetKeyword:
                                              '${quest.word} ${quest.correctAnswer}',
                                          primaryColor: theme.primaryColor,
                                          onConfirmed: () =>
                                              _submitFinalAnswer(true),
                                          onSkipped: () =>
                                              _submitFinalAnswer(false),
                                          isPositioned: false,
                                          exampleSentence:
                                              _getFormattedExampleSentence(
                                                quest,
                                              ),
                                        ),
                                      ),
                                    ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(
                                            context,
                                          ).viewInsets.bottom +
                                          60.h,
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

  Widget _buildOptionsWrap(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    bool isFinalFailure,
    bool isCompact,
    bool isHintUsed,
  ) {
    return Wrap(
      spacing: 20.w,
      runSpacing: isCompact ? 15.h : 30.h,
      alignment: WrapAlignment.center,
      children: (quest.options ?? []).asMap().entries.map((entry) {
        final bubble = CollocationOptionBubble(
          text: entry.value,
          correct: quest.correctAnswer ?? "",
          color: color,
          isDark: isDark,
          isAnswered: isAnsweredNotifier.value,
          isCorrect: isCorrectNotifier.value,
          selectedOption: _selectedOption.value,
          isFinalFailure: isFinalFailure,
          isFirstStagePassed: _isDragPassed.value,
          index: entry.key,
          isHintUsed: isHintUsed,
          onTap: () {
            if (!isAnsweredNotifier.value) {
              hapticService.light();
              _submitAnswer(entry.value, quest.correctAnswer ?? "");
            }
          },
        );

        if (isAnsweredNotifier.value || _isDragPassed.value) {
          return bubble;
        }

        return Semantics(
          label:
              'Draggable option: ${entry.value}. Double tap and hold to drag.',
          child: Draggable<String>(
            data: entry.value,
            feedback: Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.1,
                child: CollocationOptionBubble(
                  text: entry.value,
                  correct: quest.correctAnswer ?? "",
                  color: color,
                  isDark: isDark,
                  isAnswered: false,
                  isCorrect: null,
                  selectedOption: null,
                  isFinalFailure: false,
                  isFirstStagePassed: false,
                  index: entry.key,
                  isHintUsed: isHintUsed,
                  onTap: () {},
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: bubble),
            onDragStarted: () => hapticService.selection(),
            child: bubble,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstruction(Color color, bool isDark, String instruction) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        instruction.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
