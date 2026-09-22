import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
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
    with GrammarGameScreenMixin {
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

  void _submitInitialAnswer(bool correct) {
    if (isAnsweredNotifier.value) return;
    if (correct) {
      hapticService.success();
      soundService.playCorrect();
      _pendingTypeSubmit.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingTypeSubmit.value = false;
    if (correct) {
      hapticService.success();
      soundService.playCorrect();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
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
          fullSentence = (quest.question ?? "").replaceAll('___', targetText);
        }
        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _pendingTypeSubmit,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling:
                  false, // Stack needs finite space to anchor to bottom
              disablePadding: true,
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          crossAxisMargin: 0,
                          mainAxisMargin: 0,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 24.h),
                                      GrammarQuestInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                      SizedBox(height: 16.h),
                                      if (quest.grammarRule != null)
                                        Container(
                                          margin: EdgeInsets.only(bottom: 24.h),
                                          padding: EdgeInsets.all(16.r),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            border: Border.all(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.rule,
                                                    color: theme.primaryColor,
                                                    size: 16.sp,
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Text(
                                                    "GRAMMAR RULE",
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: theme.primaryColor,
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                quest.grammarRule!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              if (quest.ruleExplanation !=
                                                  null) ...[
                                                SizedBox(height: 8.h),
                                                Text(
                                                  quest.ruleExplanation!,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 14.sp,
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      if (quest.question != null)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 24.h,
                                          ),
                                          child: GrammarQuestSentence(
                                            text:
                                                (isAnsweredNotifier.value ||
                                                    _pendingTypeSubmit.value)
                                                ? fullSentence
                                                : quest.question!,
                                            isDark:
                                                Theme.of(context).brightness ==
                                                Brightness.dark,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 0.w,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 16.h),
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
                                        onQuadrantSelect: (index) {
                                          bool isCorrect =
                                              index == quest.correctAnswerIndex;
                                          _submitInitialAnswer(isCorrect);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_pendingTypeSubmit.value &&
                                  !isAnsweredNotifier.value &&
                                  targetText.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 32.h),
                                    child: TypeToConfirmOverlay(
                                      expectedText: fullSentence,
                                      primaryColor: theme.primaryColor,
                                      onConfirmed: () =>
                                          _submitFinalAnswer(true),
                                      onSkipped: () =>
                                          _submitFinalAnswer(false),
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
                    ),
            );
          },
        );
      },
    );
  }
}
