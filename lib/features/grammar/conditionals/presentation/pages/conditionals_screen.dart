import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/conditionals/presentation/widgets/conditionals_instruction.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

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

class _ConditionalsScreenState extends State<ConditionalsScreen>
    with GrammarGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<int> _targetIndex = ValueNotifier(-1);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _targetIndex.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

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
    isFirstStagePassedNotifier.addListener(_onStagePassedScroll);

    initGrammarGame();
  }

  void _onOptionSelected(int nodeIndex, int correctIndex) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      hapticService.heavy();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _targetIndex.value = nodeIndex;
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _targetIndex.value = nodeIndex;
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;
    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
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
  void onQuestionReset() {
    _targetIndex.value = -1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
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
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
            _targetIndex,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
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
                                            (isAnsweredNotifier.value
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
                                  if (isFirstStagePassedNotifier.value &&
                                      !isAnsweredNotifier.value &&
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
        (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) &&
        _targetIndex.value == i;
    final isWrong = isHit && isCorrectNotifier.value == false;
    final blockColor = isHit
        ? (isCorrectNotifier.value == false
              ? AppColors.gameIncorrect
              : AppColors.gameCorrect)
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
                            ? (isCorrectNotifier.value == false
                                  ? AppColors.gameIncorrect
                                  : AppColors.gameCorrect)
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
}
