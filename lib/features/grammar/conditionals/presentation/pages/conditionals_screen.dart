import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/grammar/conditionals/presentation/widgets/conditionals_instruction.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';

/// Screen host for Conditionals exercises, training zero, first, second, third, and mixed conditional structures.
class ConditionalsScreen extends StatefulWidget {
  /// Current level index.
  final int level;

  /// Game subtype identifier.
  final GameSubtype gameType;

  /// Creates a [ConditionalsScreen] widget.
  const ConditionalsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conditionals,
  });

  @override
  State<ConditionalsScreen> createState() => _ConditionalsScreenState();
}

class _ConditionalsScreenState extends State<ConditionalsScreen>
    with
        GameScreenMixin<ConditionalsScreen>,
        GrammarGameScreenMixin<ConditionalsScreen> {
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
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
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

  void _onOptionSelected(int nodeIndex, int correctIndex, GameQuest quest) {
    final blocState = context.read<GrammarBloc>().state;
    final isAlreadyAnswered =
        isAnsweredNotifier.value ||
        (blocState is GrammarLoaded &&
            blocState.answerStatus != AnswerStatus.unanswered);
    if (isAlreadyAnswered || isFirstStagePassedNotifier.value) return;

    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      hapticService.heavy();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _targetIndex.value = nodeIndex;
    } else {
      _targetIndex.value = nodeIndex;
      String? userAnswer = (nodeIndex < (quest.options?.length ?? 0))
          ? quest.options![nodeIndex]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;
    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      String? userAnswer =
          (quest.options != null &&
              _targetIndex.value < (quest.options?.length ?? 0))
          ? quest.options![_targetIndex.value]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
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
        final options = quest?.options ?? ["Result A", "Result B", "Result C"];

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
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact =
                            maxHeight < 620 || constraints.maxWidth < 360;
                        final double horizontalPadding = isCompact
                            ? 16.w
                            : 20.w;
                        final shouldReduceMotion =
                            VowlMotion.shouldReduceMotion(context);

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
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: isCompact ? 8.h : 12.h,
                                          ),

                                          // Centered instruction pill
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: horizontalPadding,
                                            ),
                                            child: Center(
                                              child: ConditionalsInstruction(
                                                primaryColor:
                                                    theme.primaryColor,
                                                instruction: quest.instruction,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10.h),

                                          // Clean educational conditional type badge
                                          if (quest.conditionalType != null ||
                                              quest.grammarRule != null) ...[
                                            Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        horizontalPadding,
                                                  ),
                                                  child: Center(
                                                    child:
                                                        _buildConditionalTypeBadge(
                                                          quest,
                                                          theme.primaryColor,
                                                          isDark,
                                                        ),
                                                  ),
                                                )
                                                .animate(
                                                  target: shouldReduceMotion
                                                      ? 0
                                                      : 1,
                                                )
                                                .fadeIn(
                                                  duration: shouldReduceMotion
                                                      ? Duration.zero
                                                      : 400.ms,
                                                ),
                                            SizedBox(height: 12.h),
                                          ],

                                          // Standard If-Clause Context Card
                                          Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: horizontalPadding,
                                                ),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 20.w,
                                                    vertical: isCompact
                                                        ? 14.h
                                                        : 18.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.05,
                                                              )
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20.r,
                                                        ),
                                                    border: Border.all(
                                                      color: theme.primaryColor
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: isDark
                                                            ? Colors.black
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  )
                                                            : theme.primaryColor
                                                                  .withValues(
                                                                    alpha: 0.06,
                                                                  ),
                                                        blurRadius: 10,
                                                        offset: const Offset(
                                                          0,
                                                          3,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        "IF CLAUSE",
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 11.sp,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: theme
                                                              .primaryColor,
                                                          letterSpacing: 1.2,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: isCompact
                                                            ? 6.h
                                                            : 10.h,
                                                      ),
                                                      Text(
                                                        quest.question ?? "",
                                                        textAlign:
                                                            TextAlign.center,
                                                        softWrap: true,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: isCompact
                                                              ? 16.sp
                                                              : 18.sp,
                                                          color: isDark
                                                              ? Colors.white
                                                              : AppColors
                                                                    .slate900,
                                                          height: 1.4,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .animate(
                                                target: shouldReduceMotion
                                                    ? 0
                                                    : 1,
                                              )
                                              .fadeIn(
                                                duration: shouldReduceMotion
                                                    ? Duration.zero
                                                    : 500.ms,
                                              )
                                              .slideY(
                                                begin: shouldReduceMotion
                                                    ? 0
                                                    : 0.15,
                                                end: 0,
                                              ),

                                          SizedBox(
                                            height: isCompact ? 14.h : 18.h,
                                          ),

                                          // Standard Options List
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: horizontalPadding,
                                            ),
                                            child: _buildOptionsList(
                                              quest,
                                              options,
                                              quest.correctAnswerIndex ?? 0,
                                              theme.primaryColor,
                                              isDark,
                                            ),
                                          ),

                                          SizedBox(height: 16.h),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Game Mechanism Confirmation Card (with proper standard horizontal padding)
                                  if (isFirstStagePassedNotifier.value &&
                                      !isAnsweredNotifier.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: horizontalPadding,
                                          vertical: 12.h,
                                        ),
                                        child: TypeToConfirmOverlay(
                                          expectedText: cleanTargetSentence,
                                          primaryColor: theme.primaryColor,
                                          onConfirmed: () =>
                                              _submitVerbalEvaluation(
                                                true,
                                                quest,
                                              ),
                                          onSkipped: () =>
                                              _submitVerbalEvaluation(
                                                false,
                                                quest,
                                              ),
                                          isPositioned: false,
                                          displayText:
                                              "Type the complete sentence to practice",
                                        ),
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

  Widget _buildConditionalTypeBadge(
    GrammarQuest quest,
    Color primaryColor,
    bool isDark,
  ) {
    final typeInfo = _getConditionalTypeInfo(quest);
    if (typeInfo == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            typeInfo.title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: primaryColor,
              letterSpacing: 0.2,
            ),
          ),
          if (typeInfo.subtitle.isNotEmpty) ...[
            Text(
              " • ",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Flexible(
              child: Text(
                typeInfo.subtitle,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.slate600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _ConditionalTypeInfo? _getConditionalTypeInfo(GrammarQuest quest) {
    final raw = (quest.conditionalType ?? quest.grammarRule ?? "")
        .toString()
        .toLowerCase()
        .trim();
    if (raw.isEmpty) return null;

    if (raw.contains('0') || raw.contains('zero')) {
      return const _ConditionalTypeInfo(
        "Zero Conditional",
        "General Truths & Facts",
      );
    } else if (raw.contains('1') || raw.contains('first')) {
      return const _ConditionalTypeInfo(
        "First Conditional",
        "Real Possibility",
      );
    } else if (raw.contains('2') || raw.contains('second')) {
      return const _ConditionalTypeInfo(
        "Second Conditional",
        "Hypothetical / Unreal",
      );
    } else if (raw.contains('3') || raw.contains('third')) {
      return const _ConditionalTypeInfo("Third Conditional", "Past Unreal");
    } else if (raw.contains('mixed')) {
      return const _ConditionalTypeInfo("Mixed Conditional", "Past & Present");
    }

    if (quest.grammarRule != null && quest.grammarRule!.isNotEmpty) {
      return _ConditionalTypeInfo(quest.grammarRule!, "");
    }
    return _ConditionalTypeInfo("Conditional ${quest.conditionalType}", "");
  }

  Widget _buildOptionsList(
    GameQuest quest,
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
  ) {
    return Column(
      children: List.generate(options.length, (i) {
        return _buildOptionCard(
          quest,
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
    GameQuest quest,
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

    final shouldReduceMotion = VowlMotion.shouldReduceMotion(context);
    Widget card = Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        key: ValueKey('conditional_option_$i'),
        onTap: () => _onOptionSelected(i, correctIndex, quest),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 56.h),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isHit
                ? blockColor.withValues(alpha: isDark ? 0.15 : 0.08)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: blockColor.withValues(
                alpha: (isHit || isWrong) ? 0.8 : 0.2,
              ),
              width: (isHit || isWrong) ? 2 : 1.5,
            ),
            boxShadow: [
              if (isHit)
                BoxShadow(
                  color: blockColor.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              else if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: isHit ? FontWeight.w700 : FontWeight.w600,
              color: isHit
                  ? blockColor
                  : (isDark ? Colors.white : AppColors.slate900),
              height: 1.35,
            ),
          ),
        ),
      ),
    );

    if (!shouldReduceMotion) {
      card = card
          .animate(target: isHit ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.02, 1.02),
            duration: 200.ms,
          );
    }

    return card;
  }
}

class _ConditionalTypeInfo {
  final String title;
  final String subtitle;
  const _ConditionalTypeInfo(this.title, this.subtitle);
}
