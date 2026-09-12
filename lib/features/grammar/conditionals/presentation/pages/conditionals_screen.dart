import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/conditionals/presentation/widgets/conditionals_instruction.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

import 'package:vowl/core/utils/locale_service.dart';

class ConditionalsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConditionalsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conditionals,
  });

  @override
  State<ConditionalsScreen> createState() => _ConditionalsScreenState();
}

class _ConditionalsScreenState extends State<ConditionalsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<int> _targetIndex = ValueNotifier(-1);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _targetIndex.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _lastProcessedIndex = -1;
  int? _lastLives;

  void _onStagePassedScroll() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _isFirstStagePassed.addListener(_onStagePassedScroll);

    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onOptionSelected(int nodeIndex, int correctIndex) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      _isFirstStagePassed.value = true;
      _targetIndex.value = nodeIndex;
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      _targetIndex.value = nodeIndex;
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;
    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }

    // Scroll back to top so the user can read the Result and Explanation cards.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesRestored) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;
            _targetIndex.value = -1;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'LOGIC LORD!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;
        final options = quest?.options ?? ["RESULT A", "RESULT B", "RESULT C"];

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.correctAnswer ?? quest.sentence ?? "";
          if (sentence.isNotEmpty) {
            cleanTargetSentence = sentence
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (_targetIndex.value != -1) {
            cleanTargetSentence =
                "${quest.question} ${options[_targetIndex.value]}"
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim();
          }
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _isFirstStagePassed,
            _targetIndex,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,
              useScrolling: false,
              onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
              onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              crossAxisMargin: 2,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Builder(
                                      builder: (context) {
                                        final maxHeight = constraints.maxHeight;
                                        final isCompact = maxHeight < 580;

                                        final double estimatedContentHeight =
                                            (isCompact ? 30.h : 40.h) +
                                            (isCompact ? 70.h : 100.h) +
                                            (_isAnswered.value
                                                ? (isCompact ? 50.h : 90.h)
                                                : 0) +
                                            40.h;
                                        final remainingHeight =
                                            maxHeight - estimatedContentHeight;

                                        final double gapUnit =
                                            remainingHeight > 0
                                            ? remainingHeight / 5
                                            : 0;
                                        final double gapTop =
                                            remainingHeight > 0
                                            ? (gapUnit * 1).clamp(4.0, 15.0)
                                            : 4.0;
                                        final double gapMiddle =
                                            remainingHeight > 0
                                            ? (gapUnit * 1.5).clamp(6.0, 20.0)
                                            : 6.0;
                                        final double gapBottom =
                                            remainingHeight > 0
                                            ? (gapUnit * 2.5).clamp(10.0, 30.0)
                                            : 10.0;

                                        return Column(
                                          children: [
                                            SizedBox(height: gapTop),
                                            isCompact
                                                ? SizedBox(
                                                    height: 25.h,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child:
                                                          ConditionalsInstruction(
                                                            primaryColor: theme
                                                                .primaryColor,
                                                            instruction: quest
                                                                .instruction,
                                                          ),
                                                    ),
                                                  )
                                                : ConditionalsInstruction(
                                                    primaryColor:
                                                        theme.primaryColor,
                                                    instruction:
                                                        quest.instruction,
                                                  ),
                                            SizedBox(height: gapMiddle),

                                            if (quest.conditionalType !=
                                                null) ...[
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: 8.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.r,
                                                      ),
                                                  border: Border.all(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      "TYPE: ${quest.conditionalType!.toUpperCase()}",
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 12.sp,
                                                        color:
                                                            theme.primaryColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          "0: Fact  ",
                                                          style: TextStyle(
                                                            fontSize: 10.sp,
                                                            color:
                                                                quest.conditionalType ==
                                                                        '0' ||
                                                                    quest.conditionalType ==
                                                                        'zero'
                                                                ? theme
                                                                      .primaryColor
                                                                : theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.5,
                                                                      ),
                                                            fontWeight:
                                                                quest.conditionalType ==
                                                                        '0' ||
                                                                    quest.conditionalType ==
                                                                        'zero'
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .normal,
                                                          ),
                                                        ),
                                                        Text(
                                                          "|  1: Real  ",
                                                          style: TextStyle(
                                                            fontSize: 10.sp,
                                                            color:
                                                                quest.conditionalType ==
                                                                        '1' ||
                                                                    quest.conditionalType ==
                                                                        'first'
                                                                ? theme
                                                                      .primaryColor
                                                                : theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.5,
                                                                      ),
                                                            fontWeight:
                                                                quest.conditionalType ==
                                                                        '1' ||
                                                                    quest.conditionalType ==
                                                                        'first'
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .normal,
                                                          ),
                                                        ),
                                                        Text(
                                                          "|  2: Unreal  ",
                                                          style: TextStyle(
                                                            fontSize: 10.sp,
                                                            color:
                                                                quest.conditionalType ==
                                                                        '2' ||
                                                                    quest.conditionalType ==
                                                                        'second'
                                                                ? theme
                                                                      .primaryColor
                                                                : theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.5,
                                                                      ),
                                                            fontWeight:
                                                                quest.conditionalType ==
                                                                        '2' ||
                                                                    quest.conditionalType ==
                                                                        'second'
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .normal,
                                                          ),
                                                        ),
                                                        Text(
                                                          "|  3: Past",
                                                          style: TextStyle(
                                                            fontSize: 10.sp,
                                                            color:
                                                                quest.conditionalType ==
                                                                        '3' ||
                                                                    quest.conditionalType ==
                                                                        'third'
                                                                ? theme
                                                                      .primaryColor
                                                                : theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.5,
                                                                      ),
                                                            fontWeight:
                                                                quest.conditionalType ==
                                                                        '3' ||
                                                                    quest.conditionalType ==
                                                                        'third'
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .normal,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ).animate().fadeIn(
                                                duration: 400.ms,
                                              ),
                                              SizedBox(
                                                height: isCompact ? 12.h : 20.h,
                                              ),
                                            ],

                                            // Context Card
                                            Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 24.w,
                                                  ),
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding: EdgeInsets.all(
                                                      isCompact ? 12.r : 22.r,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                )
                                                          : Colors.black
                                                                .withValues(
                                                                  alpha: 0.03,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24.r,
                                                          ),
                                                      border: Border.all(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          "IF CONDITION",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Outfit',
                                                            fontSize: isCompact
                                                                ? 8.sp
                                                                : 10.sp,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            color: theme
                                                                .primaryColor,
                                                            letterSpacing: 2,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: isCompact
                                                              ? 6.h
                                                              : 12.h,
                                                        ),
                                                        Text(
                                                          quest.question ?? "",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Outfit',
                                                            fontSize: isCompact
                                                                ? 16.sp
                                                                : 20.sp,
                                                            color: isDark
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87,
                                                            height: 1.4,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                .animate()
                                                .fadeIn(duration: 600.ms)
                                                .slideY(begin: 0.2, end: 0),

                                            // Result
                                            if (_isAnswered.value) ...[
                                              SizedBox(height: gapMiddle),
                                              _buildResult(
                                                quest,
                                                theme.primaryColor,
                                                isDark,
                                                isCompact,
                                              ),
                                            ],

                                            SizedBox(
                                              height: isCompact ? 16.h : 32.h,
                                            ),

                                            // Options List
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24.w,
                                              ),
                                              child: _buildOptionsList(
                                                options,
                                                quest.correctAnswerIndex ?? 0,
                                                theme.primaryColor,
                                                isDark,
                                              ),
                                            ),

                                            SizedBox(height: gapBottom),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  if (_isFirstStagePassed.value &&
                                      !_isAnswered.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: TypeToConfirmOverlay(
                                        expectedText: cleanTargetSentence,
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitVerbalEvaluation(true),
                                        onSkipped: () =>
                                            _submitVerbalEvaluation(false),
                                        isPositioned: false,
                                        displayText:
                                            "Type the full sentence to lock it in",
                                      ),
                                    ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom >
                                              0
                                          ? MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom +
                                                40.h
                                          : 60.h,
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

  Widget _buildOptionsList(
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
  ) {
    return Column(
      children: List.generate(options.length, (i) {
        return _buildOptionCard(
          i,
          options[i],
          correctIndex,
          primaryColor,
          isDark,
        );
      }),
    );
  }

  Widget _buildOptionCard(
    int i,
    String text,
    int correctIndex,
    Color primaryColor,
    bool isDark,
  ) {
    final isHit =
        (_isAnswered.value || _isFirstStagePassed.value) &&
        _targetIndex.value == i;
    final isWrong = isHit && _isCorrect.value == false;
    final blockColor = isHit
        ? (_isCorrect.value == false ? Colors.redAccent : Colors.greenAccent)
        : primaryColor;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child:
          Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onOptionSelected(i, correctIndex),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 65.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: blockColor.withValues(
                          alpha: (isHit || isWrong) ? 0.6 : 0.2,
                        ),
                        width: 2,
                      ),
                      boxShadow: [
                        if (isHit)
                          BoxShadow(
                            color: blockColor.withValues(alpha: 0.1),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: (isHit || isWrong)
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isHit
                            ? (_isCorrect.value == false
                                  ? Colors.redAccent
                                  : Colors.greenAccent)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ),
              )
              .animate(target: isHit ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.02, 1.02),
                duration: 200.ms,
              ),
    );
  }

  Widget _buildResult(
    GrammarQuest quest,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final bool correct = _isCorrect.value == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 10.r : 24.r),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
          border: Border.all(
            color: displayColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: displayColor,
              size: isCompact ? 24.r : 40.r,
            ),
            SizedBox(height: isCompact ? 4.h : 12.h),
            Text(
              correct
                  ? context
                        .tr('games.correct', fallback: 'Correct')
                        .toUpperCase()
                  : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 12.sp : 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            if (quest.grammarRule != null) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: displayColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  quest.grammarRule!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: displayColor,
                  ),
                ),
              ),
            ],
            if (quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
