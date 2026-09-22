import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/widgets/article_insertion_instruction.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/widgets/article_floating_orb.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class ArticleInsertionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ArticleInsertionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.articleInsertion,
  });

  @override
  State<ArticleInsertionScreen> createState() => _ArticleInsertionScreenState();
}

class _ArticleInsertionScreenState extends State<ArticleInsertionScreen>
    with GrammarGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<String?> _selectedArticle = ValueNotifier(null);
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _selectedArticle.dispose();
    _pendingJigsaw.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initGrammarGame();
  }

  void _onPop(String article, String correctAnswer) {
    if (isAnsweredNotifier.value || _pendingJigsaw.value) return;

    hapticService.selection();
    bool isCorrect = article.toLowerCase() == correctAnswer.toLowerCase();

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      _selectedArticle.value = article;
      _pendingJigsaw.value = true;
      _scrollToBottom();
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _selectedArticle.value = article;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitFinalAnswer(bool correct) {
    _pendingJigsaw.value = false;
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = correct;

    if (correct) {
      hapticService.success();
      soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  List<InlineSpan> _buildSentenceWithBlank(
    String template,
    String? selected,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final parts = template.split(RegExp(r'_{3,}'));
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child:
                Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8.w : 12.w,
                        vertical: isCompact ? 2.h : 4.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected != null
                                ? primaryColor
                                : (isDark ? Colors.white38 : Colors.black38),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        selected == null
                            ? "      "
                            : (selected.toLowerCase() == "(no article)"
                                  ? "Ø"
                                  : selected),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isCompact ? 18.sp : 22.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    )
                    .animate(target: selected != null ? 1 : 0)
                    .shimmer(duration: 2.seconds),
          ),
        );
      }
    }
    return spans;
  }

  @override
  void onQuestionReset() {
    _selectedArticle.value = null;

    _pendingJigsaw.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;
        final options = quest?.options ?? ["a", "an", "the", "Ø"];
        final correctAnswer = quest?.correctAnswer ?? "";

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            _selectedArticle,
            showConfettiNotifier,
            _pendingJigsaw,
          ]),
          builder: (context, _) {
            String cleanTargetSentence = "";
            if (quest != null) {
              final sentence = quest.sentence ?? quest.question ?? "";
              String fullSentence = sentence;
              if (sentence.contains("___") && _selectedArticle.value != null) {
                String replaceWith =
                    _selectedArticle.value!.toLowerCase() == "(no article)"
                    ? ""
                    : _selectedArticle.value!;
                fullSentence = sentence.replaceFirst(
                  RegExp(r'_{3,}'),
                  replaceWith,
                );
              }
              cleanTargetSentence = fullSentence
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
              if (cleanTargetSentence.isNotEmpty) {
                cleanTargetSentence =
                    cleanTargetSentence[0].toUpperCase() +
                    cleanTargetSentence.substring(1);
              }
            }

            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false, // CustomScrollView handles it internally
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
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
                                  SliverFillRemaining(
                                    hasScrollBody: true,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final maxHeight =
                                                  constraints.maxHeight;
                                              final isCompact = maxHeight < 580;

                                              final double
                                              estimatedContentHeight =
                                                  (isCompact ? 30.h : 40.h) +
                                                  (isCompact ? 90.h : 130.h) +
                                                  40.h;
                                              final remainingHeight =
                                                  maxHeight -
                                                  estimatedContentHeight;

                                              final double gapUnit =
                                                  remainingHeight > 0
                                                  ? remainingHeight / 5
                                                  : 0;
                                              final double gapTop =
                                                  remainingHeight > 0
                                                  ? (gapUnit * 1).clamp(
                                                      6.0,
                                                      20.0,
                                                    )
                                                  : 6.0;
                                              final double gapMiddle =
                                                  remainingHeight > 0
                                                  ? (gapUnit * 1.5).clamp(
                                                      10.0,
                                                      25.0,
                                                    )
                                                  : 10.0;
                                              final double gapBottom =
                                                  remainingHeight > 0
                                                  ? (gapUnit * 2.5).clamp(
                                                      15.0,
                                                      40.0,
                                                    )
                                                  : 15.0;

                                              return Column(
                                                children: [
                                                  SizedBox(height: gapTop),
                                                  isCompact
                                                      ? SizedBox(
                                                          height: 25.h,
                                                          child: FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: ArticleInsertionInstruction(
                                                              primaryColor: theme
                                                                  .primaryColor,
                                                              instruction: context.tr(
                                                                'games.article_insertion_instruction',
                                                                fallback:
                                                                    "Pop the correct article orb",
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : ArticleInsertionInstruction(
                                                          primaryColor: theme
                                                              .primaryColor,
                                                          instruction: context.tr(
                                                            'games.article_insertion_instruction',
                                                            fallback:
                                                                "Pop the correct article orb",
                                                          ),
                                                        ),
                                                  SizedBox(height: gapMiddle),

                                                  if (quest.articleRule !=
                                                      null) ...[
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 16.w,
                                                            vertical: 6.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                        border: Border.all(
                                                          color: theme
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        quest.articleRule!,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 12.sp,
                                                          color: theme
                                                              .primaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ).animate().fadeIn(
                                                      duration: 400.ms,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 12.h
                                                          : 20.h,
                                                    ),
                                                  ],

                                                  // Context Card
                                                  Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 24.w,
                                                            ),
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                isCompact
                                                                    ? 14.r
                                                                    : 22.r,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: isDark
                                                                ? Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.05,
                                                                      )
                                                                : Colors.black
                                                                      .withValues(
                                                                        alpha:
                                                                            0.03,
                                                                      ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  28.r,
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
                                                          child: RichText(
                                                            textAlign: TextAlign
                                                                .center,
                                                            text: TextSpan(
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Outfit',
                                                                fontSize:
                                                                    isCompact
                                                                    ? 16.sp
                                                                    : 20.sp,
                                                                color: isDark
                                                                    ? Colors
                                                                          .white
                                                                    : Colors
                                                                          .black87,
                                                                height: 1.5,
                                                              ),
                                                              children: _buildSentenceWithBlank(
                                                                quest.sentence ??
                                                                    quest
                                                                        .question ??
                                                                    "___ sentence.",
                                                                _selectedArticle
                                                                    .value,
                                                                theme
                                                                    .primaryColor,
                                                                isDark,
                                                                isCompact,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .animate()
                                                      .fadeIn(duration: 600.ms)
                                                      .slideY(
                                                        begin: 0.2,
                                                        end: 0,
                                                      ),

                                                  // Floating Orb Bubble Area
                                                  Expanded(
                                                    child: Center(
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              if (options
                                                                  .isNotEmpty)
                                                                ArticleFloatingOrb(
                                                                  article:
                                                                      options[0],
                                                                  index: 0,
                                                                  onTap: () => _onPop(
                                                                    options[0],
                                                                    correctAnswer,
                                                                  ),
                                                                  primaryColor:
                                                                      theme
                                                                          .primaryColor,
                                                                  isDark:
                                                                      isDark,
                                                                  isAnswered:
                                                                      isAnsweredNotifier
                                                                          .value ||
                                                                      _pendingJigsaw
                                                                          .value,
                                                                  isSelected:
                                                                      _selectedArticle
                                                                          .value ==
                                                                      options[0],
                                                                  isCorrectAnswer:
                                                                      options[0]
                                                                          .toLowerCase() ==
                                                                      correctAnswer
                                                                          .toLowerCase(),
                                                                  isFinalFailure:
                                                                      state
                                                                          is GrammarLoaded &&
                                                                      state
                                                                          .isFinalFailure,
                                                                  isCompact:
                                                                      isCompact,
                                                                ),
                                                              if (options
                                                                      .length >
                                                                  2)
                                                                SizedBox(
                                                                  height:
                                                                      isCompact
                                                                      ? 10.h
                                                                      : 20.h,
                                                                ),
                                                              if (options
                                                                      .length >
                                                                  2)
                                                                ArticleFloatingOrb(
                                                                  article:
                                                                      options[2],
                                                                  index: 2,
                                                                  onTap: () => _onPop(
                                                                    options[2],
                                                                    correctAnswer,
                                                                  ),
                                                                  primaryColor:
                                                                      theme
                                                                          .primaryColor,
                                                                  isDark:
                                                                      isDark,
                                                                  isAnswered:
                                                                      isAnsweredNotifier
                                                                          .value ||
                                                                      _pendingJigsaw
                                                                          .value,
                                                                  isSelected:
                                                                      _selectedArticle
                                                                          .value ==
                                                                      options[2],
                                                                  isCorrectAnswer:
                                                                      options[2]
                                                                          .toLowerCase() ==
                                                                      correctAnswer
                                                                          .toLowerCase(),
                                                                  isFinalFailure:
                                                                      state
                                                                          is GrammarLoaded &&
                                                                      state
                                                                          .isFinalFailure,
                                                                  isCompact:
                                                                      isCompact,
                                                                ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                            width: isCompact
                                                                ? 20.w
                                                                : 40.w,
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  top: isCompact
                                                                      ? 30.h
                                                                      : 50.h,
                                                                ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                if (options
                                                                        .length >
                                                                    1)
                                                                  ArticleFloatingOrb(
                                                                    article:
                                                                        options[1],
                                                                    index: 1,
                                                                    onTap: () => _onPop(
                                                                      options[1],
                                                                      correctAnswer,
                                                                    ),
                                                                    primaryColor:
                                                                        theme
                                                                            .primaryColor,
                                                                    isDark:
                                                                        isDark,
                                                                    isAnswered:
                                                                        isAnsweredNotifier
                                                                            .value ||
                                                                        _pendingJigsaw
                                                                            .value,
                                                                    isSelected:
                                                                        _selectedArticle
                                                                            .value ==
                                                                        options[1],
                                                                    isCorrectAnswer:
                                                                        options[1]
                                                                            .toLowerCase() ==
                                                                        correctAnswer
                                                                            .toLowerCase(),
                                                                    isFinalFailure:
                                                                        state
                                                                            is GrammarLoaded &&
                                                                        state
                                                                            .isFinalFailure,
                                                                    isCompact:
                                                                        isCompact,
                                                                  ),
                                                                if (options
                                                                        .length >
                                                                    3)
                                                                  SizedBox(
                                                                    height:
                                                                        isCompact
                                                                        ? 10.h
                                                                        : 20.h,
                                                                  ),
                                                                if (options
                                                                        .length >
                                                                    3)
                                                                  ArticleFloatingOrb(
                                                                    article:
                                                                        options[3],
                                                                    index: 3,
                                                                    onTap: () => _onPop(
                                                                      options[3],
                                                                      correctAnswer,
                                                                    ),
                                                                    primaryColor:
                                                                        theme
                                                                            .primaryColor,
                                                                    isDark:
                                                                        isDark,
                                                                    isAnswered:
                                                                        isAnsweredNotifier
                                                                            .value ||
                                                                        _pendingJigsaw
                                                                            .value,
                                                                    isSelected:
                                                                        _selectedArticle
                                                                            .value ==
                                                                        options[3],
                                                                    isCorrectAnswer:
                                                                        options[3]
                                                                            .toLowerCase() ==
                                                                        correctAnswer
                                                                            .toLowerCase(),
                                                                    isFinalFailure:
                                                                        state
                                                                            is GrammarLoaded &&
                                                                        state
                                                                            .isFinalFailure,
                                                                    isCompact:
                                                                        isCompact,
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  SizedBox(height: gapBottom),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_pendingJigsaw.value &&
                                      !isAnsweredNotifier.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: TypeToConfirmOverlay(
                                        expectedText: cleanTargetSentence,
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitFinalAnswer(true),
                                        onSkipped: () =>
                                            _submitFinalAnswer(false),
                                        isPositioned: false,
                                        displayText:
                                            "Type the full sentence with the article to lock it in",
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
}
