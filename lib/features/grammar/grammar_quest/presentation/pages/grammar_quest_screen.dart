import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_instruction.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_compass.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_sentence.dart';

class GrammarQuestScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GrammarQuestScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.grammarQuest,
  });
  @override
  State<GrammarQuestScreen> createState() => _GrammarQuestScreenState();
}

class _GrammarQuestScreenState extends State<GrammarQuestScreen>
    with
        GameScreenMixin<GrammarQuestScreen>,
        GrammarGameScreenMixin<GrammarQuestScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _pendingTypeSubmit.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initGrammarGame();
  }

  void _submitInitialAnswer(bool correct, GameQuest quest, int selectedIndex) {
    if (isAnsweredNotifier.value || _pendingTypeSubmit.value) return;
    final state = context.read<GrammarBloc>().state;
    if (state is GrammarLoaded &&
        state.answerStatus != AnswerStatus.unanswered) {
      return;
    }

    if (correct) {
      hapticService.success();
      soundService.playCorrect();
      _pendingTypeSubmit.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      String? userAnswer =
          (quest.options != null && selectedIndex < quest.options!.length)
          ? quest.options![selectedIndex]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  void _submitFinalAnswer(bool correct, GameQuest quest) {
    _pendingTypeSubmit.value = false;
    if (correct) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: null);
    }
  }

  @override
  void onQuestionReset() {
    _pendingTypeSubmit.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);
    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        String targetText = "";
        String fullSentence = "";
        if (quest != null) {
          if (quest.options != null &&
              quest.options!.isNotEmpty &&
              quest.correctAnswerIndex != null &&
              quest.correctAnswerIndex! < quest.options!.length) {
            targetText = quest.options![quest.correctAnswerIndex!];
          } else {
            targetText = quest.correctAnswer ?? quest.sentence ?? "";
          }
          final baseSentence = quest.sentenceWithBlank ?? quest.question ?? "";
          if (baseSentence.contains('___')) {
            fullSentence = baseSentence.replaceAll('___', targetText);
          } else if (quest.sentence != null && quest.sentence!.isNotEmpty) {
            fullSentence = quest.sentence!;
          } else {
            fullSentence = baseSentence.isNotEmpty ? baseSentence : targetText;
          }
        }
        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _pendingTypeSubmit,
          ]),
          builder: (context, _) {
            final isAnswered =
                isAnsweredNotifier.value ||
                (state is GrammarLoaded &&
                    state.answerStatus != AnswerStatus.unanswered);
            final isCorrect =
                isCorrectNotifier.value ??
                (state is GrammarLoaded &&
                    state.answerStatus == AnswerStatus.correct);

            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnswered,
              isCorrect: isCorrect,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling:
                  false, // Stack needs finite space to anchor to bottom
              disablePadding: true,
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 360;
                        final isCompact = constraints.maxHeight < 600;

                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              crossAxisMargin: 0,
                              mainAxisMargin: 0,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverPadding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isNarrow ? 16.w : 20.w,
                                    ),
                                    sliver: SliverToBoxAdapter(
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: isCompact ? 16.h : 20.h,
                                          ),
                                          GrammarQuestInstruction(
                                            primaryColor: theme.primaryColor,
                                            instruction: quest.instruction,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 12.h : 16.h,
                                          ),
                                          if (quest.grammarRule != null)
                                            Container(
                                              key: const ValueKey(
                                                'grammar_rule_box',
                                              ),
                                              margin: EdgeInsets.only(
                                                bottom: isCompact ? 16.h : 20.h,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16.w,
                                                vertical: 14.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
                                                border: Border.all(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.25),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.rule_rounded,
                                                        color:
                                                            theme.primaryColor,
                                                        size: 16.r,
                                                      ),
                                                      SizedBox(width: 8.w),
                                                      Text(
                                                        "GRAMMAR RULE",
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 12.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: theme
                                                              .primaryColor,
                                                          letterSpacing: 1.2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8.h),
                                                  Text(
                                                    quest.grammarRule!,
                                                    textAlign: TextAlign.center,
                                                    softWrap: true,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                  if (quest.ruleExplanation !=
                                                      null) ...[
                                                    SizedBox(height: 6.h),
                                                    Text(
                                                      quest.ruleExplanation!,
                                                      textAlign:
                                                          TextAlign.center,
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 13.5.sp,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color:
                                                            Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.dark
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  )
                                                            : Colors.black87
                                                                  .withValues(
                                                                    alpha: 0.75,
                                                                  ),
                                                        height: 1.45,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          if (quest.sentenceWithBlank != null ||
                                              quest.question != null)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: isCompact ? 16.h : 20.h,
                                              ),
                                              child: GrammarQuestSentence(
                                                text:
                                                    (isAnsweredNotifier.value ||
                                                        _pendingTypeSubmit
                                                            .value)
                                                    ? fullSentence
                                                    : (quest.sentenceWithBlank ??
                                                          quest.question!),
                                                isDark:
                                                    Theme.of(
                                                      context,
                                                    ).brightness ==
                                                    Brightness.dark,
                                                isCompact: isCompact,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isNarrow ? 16.w : 20.w,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: isCompact ? 8.h : 16.h,
                                          ),
                                          GrammarQuestCompass(
                                            options: quest.options ?? [],
                                            correctAnswerIndex:
                                                quest.correctAnswerIndex ?? 0,
                                            primaryColor: theme.primaryColor,
                                            isDark:
                                                Theme.of(context).brightness ==
                                                Brightness.dark,
                                            isAnswered:
                                                isAnsweredNotifier.value ||
                                                _pendingTypeSubmit.value,
                                            isCorrect: isCorrectNotifier.value,
                                            isCompact: isCompact,
                                            onQuadrantSelect: (index) {
                                              bool isCorrect =
                                                  index ==
                                                  quest.correctAnswerIndex;
                                              _submitInitialAnswer(
                                                isCorrect,
                                                quest,
                                                index,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_pendingTypeSubmit.value &&
                                      !isAnsweredNotifier.value &&
                                      targetText.isNotEmpty)
                                    SliverPadding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isNarrow ? 16.w : 20.w,
                                      ).copyWith(top: 24.h),
                                      sliver: SliverToBoxAdapter(
                                        child: TypeToConfirmOverlay(
                                          expectedText: fullSentence,
                                          primaryColor: theme.primaryColor,
                                          title: 'Confirm Sentence',
                                          subtitle:
                                              'Type the completed sentence to finish',
                                          hintText: 'Type the sentence here...',
                                          onConfirmed: () =>
                                              _submitFinalAnswer(true, quest),
                                          onSkipped: () =>
                                              _submitFinalAnswer(false, quest),
                                          allowSkip: true,
                                          isPositioned: false,
                                        ),
                                      ),
                                    ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          (_pendingTypeSubmit.value &&
                                              !isAnsweredNotifier.value &&
                                              targetText.isNotEmpty)
                                          ? MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom +
                                                60.h
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
}
