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
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocation_anchor_bubble.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocation_option_bubble.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocations_wrong_pairs.dart';
import 'package:vowl/core/presentation/game_mechanics/context_sentence_builder.dart';

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
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isDragPassed = ValueNotifier(false);
  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

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
    _selectedOption.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered.value || _isDragPassed.value || _selectedOption.value != null) return;

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    _selectedOption.value = selected;

    if (isCorrect) {
      _hapticService.selection();
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
      _isAnswered.value = true;
      _isCorrect.value = false;
      _hapticService.error();
      _soundService.playWrong();
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  String? _getFormattedExampleSentence(VocabularyQuest quest) {
    if (quest.contextSentence == null || quest.contextSentence!.isEmpty) return null;
    
    final sentence = quest.contextSentence!;
    final word = quest.word ?? "";
    final answer = quest.correctAnswer ?? "";

    // Determine which part of the collocation is missing in the sentence
    final replacementWord = sentence.contains(answer) ? word : answer;
    
    return sentence.replaceAll('__', replacementWord);
  }

  void _submitFinalAnswer(bool nailedIt) {
    if (_isAnswered.value && _isCorrect.value != null) return;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;

          if (isNewQuestion || isRetry) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
              );
            }
            _lastQuest = state.currentQuest;
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isDragPassed.value = false;
            _selectedOption.value = null;
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
            title: 'PAIR MASTER!',
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
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isDragPassed, _selectedOption]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              hasStage2: true,
              onContinue: () {
                final currentState = context.read<VocabularyBloc>().state;
                if (currentState is VocabularyLoaded &&
                    !currentState.isFinalFailure &&
                    _isCorrect.value == false) {
                  _isAnswered.value = false;
                  _isCorrect.value = null;
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
              onHint: () =>
                  context.read<VocabularyBloc>().add(const VocabularyHintUsed()),
              useScrolling: false,
              disablePadding: true,
              child: quest == null
                  ? const SizedBox()
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
                        final remainingHeight = maxHeight - estimatedContentHeight;

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
                              thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: (!_isDragPassed.value) ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: IgnorePointer(
                                      ignoring: _isDragPassed.value,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minHeight: maxHeight),
                                        child: Column(
                                          children: [
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: gapTop),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                                                      child: _buildInstruction(theme.primaryColor, isDark, quest.instruction),
                                                    ),
                                                    SizedBox(height: gapInstruction),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                                                      child: DragTarget<String>(
                                                        onWillAcceptWithDetails: (details) {
                                                          _hapticService.selection();
                                                          return !_isAnswered.value && !_isDragPassed.value;
                                                        },
                                                        onAcceptWithDetails: (details) {
                                                          _submitAnswer(details.data, quest.correctAnswer ?? "");
                                                        },
                                                        builder: (context, candidateData, rejectedData) {
                                                          bool isHovered = candidateData.isNotEmpty;
                                                          return AnimatedScale(
                                                            scale: isHovered ? 1.05 : 1.0,
                                                            duration: 200.ms,
                                                            curve: Curves.easeOutBack,
                                                            child: AnimatedContainer(
                                                              duration: 200.ms,
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(40.r),
                                                                boxShadow: isHovered
                                                                    ? [
                                                                        BoxShadow(
                                                                          color: theme.primaryColor.withValues(alpha: 0.8),
                                                                          blurRadius: 40,
                                                                          spreadRadius: 10,
                                                                        ),
                                                                      ]
                                                                    : [],
                                                              ),
                                                              child: CollocationAnchorBubble(
                                                                text: quest.word ?? "",
                                                                color: theme.primaryColor,
                                                                isDark: isDark,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: gapAnchor),
                                                    isCompact
                                                        ? SizedBox(
                                                            height: 100.h,
                                                            child: FittedBox(
                                                              fit: BoxFit.scaleDown,
                                                              child: SizedBox(
                                                                width: constraints.maxWidth,
                                                                child: _buildOptionsWrap(
                                                                  quest,
                                                                  theme.primaryColor,
                                                                  isDark,
                                                                  state is VocabularyLoaded ? state.isFinalFailure : false,
                                                                  isCompact,
                                                                  state is VocabularyLoaded ? state.hintUsed : false,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : _buildOptionsWrap(
                                                            quest,
                                                            theme.primaryColor,
                                                            isDark,
                                                            state is VocabularyLoaded ? state.isFinalFailure : false,
                                                            isCompact,
                                                            state is VocabularyLoaded ? state.hintUsed : false,
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
                                  if (_isDragPassed.value && (!_isAnswered.value || _isCorrect.value == null))
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                                        child: Column(
                                          children: [
                                            if (quest.wrongCollocations != null && quest.wrongCollocations!.isNotEmpty) ...[
                                              Builder(
                                                builder: (context) {
                                                  final correctPair = '${quest.word} ${quest.correctAnswer}'.toLowerCase().trim();
                                                  final filteredWrongPairs = quest.wrongCollocations!
                                                      .where((w) => w.toLowerCase().trim() != correctPair)
                                                      .toList();
          
                                                  if (filteredWrongPairs.isEmpty) return const SizedBox.shrink();
          
                                                  return Column(
                                                    children: [
                                                      CollocationsWrongPairs(
                                                        wrongCollocations: filteredWrongPairs,
                                                        color: theme.primaryColor,
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
                                  SliverToBoxAdapter(
                                    child: SizedBox(height: (_isDragPassed.value && (!_isAnswered.value || _isCorrect.value == null)) ? 380.h : 60.h),
                                  ),
                                ],
                              ),
                            ),
                            if (_isDragPassed.value && (!_isAnswered.value || _isCorrect.value == null))
                              ContextSentenceBuilder(
                                targetKeyword: '${quest.word} ${quest.correctAnswer}',
                                primaryColor: theme.primaryColor,
                                onConfirmed: () => _submitFinalAnswer(true),
                                onSkipped: () => _submitFinalAnswer(false),
                                isPositioned: true,
                                exampleSentence: _getFormattedExampleSentence(quest),
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
          isAnswered: _isAnswered.value,
          isCorrect: _isCorrect.value,
          selectedOption: _selectedOption.value,
          isFinalFailure: isFinalFailure,
          isFirstStagePassed: _isDragPassed.value,
          index: entry.key,
          isHintUsed: isHintUsed,
          onTap: () {
            if (!_isAnswered.value) {
              _hapticService.light();
              _submitAnswer(entry.value, quest.correctAnswer ?? "");
            }
          },
        );

        if (_isAnswered.value || _isDragPassed.value) {
          return bubble;
        }

        return Draggable<String>(
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
          onDragStarted: () => _hapticService.selection(),
          child: bubble,
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
        )
        .animate()
        .shimmer(duration: 2.seconds);
  }
}
