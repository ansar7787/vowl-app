import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/widgets/modals_selection_instruction.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/widgets/modals_rotary_dial.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class ModalsSelectionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ModalsSelectionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.modalsSelection,
  });

  @override
  State<ModalsSelectionScreen> createState() => _ModalsSelectionScreenState();
}

class _ModalsSelectionScreenState extends State<ModalsSelectionScreen>
    with
        GameScreenMixin<ModalsSelectionScreen>,
        GrammarGameScreenMixin<ModalsSelectionScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _selectedIndex.dispose();
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

  void _submitAnswer(int correctIndex, GameQuest quest) {
    if (isAnsweredNotifier.value || _pendingJigsaw.value) return;
    final state = context.read<GrammarBloc>().state;
    if (state is GrammarLoaded &&
        state.answerStatus != AnswerStatus.unanswered) {
      return;
    }

    bool isCorrect = _selectedIndex.value == correctIndex;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      _pendingJigsaw.value = true;

      // Auto-scroll to show the second stage (TypeToConfirm Jigsaw) at the bottom
      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      String? userAnswer =
          (quest.options != null &&
              _selectedIndex.value < (quest.options?.length ?? 0))
          ? quest.options![_selectedIndex.value]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  void _submitFinalAnswer(bool correct, GameQuest quest) {
    _scrollTimer?.cancel();
    _pendingJigsaw.value = false;

    if (correct) {
      submitCorrectAnswer();
    } else {
      String? userAnswer =
          (quest.options != null &&
              _selectedIndex.value < (quest.options?.length ?? 0))
          ? quest.options![_selectedIndex.value]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  List<InlineSpan> _buildSentenceWithBlank(
    String template,
    String? selected,
    Color primaryColor,
    bool isDark,
    double baseFontSize,
  ) {
    final blankTextStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: baseFontSize,
      fontWeight: FontWeight.w700,
      color: primaryColor,
    );

    if (!template.contains(RegExp(r'_{3,}'))) {
      return [
        TextSpan(text: template),
        if (selected != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primaryColor, width: 2.5),
                ),
              ),
              child: Text(
                selected,
                style: blankTextStyle,
              ),
            ),
          ),
      ];
    }
    final parts = template.split(RegExp(r'_{3,}'));
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected != null
                        ? primaryColor
                        : (isDark ? Colors.white38 : Colors.black38),
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                selected ?? "       ",
                style: blankTextStyle,
              ),
            ),
          ),
        );
      }
    }
    return spans;
  }

  Widget _buildGrammarRule(
    String rule,
    Color primaryColor,
    bool isDark,
    double horizontalMargin,
  ) {
    return Container(
      key: const ValueKey('grammar_rule_box'),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: primaryColor,
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                "Grammar Rule",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            rule,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : primaryColor.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextCard(
    GrammarQuest quest,
    List<String> options,
    Color primaryColor,
    bool isDark,
    double horizontalMargin,
    bool isNarrow,
  ) {
    final template = quest.sentenceWithBlank ??
        quest.question ??
        quest.sentence ??
        "___ sentence.";
    final baseFontSize = isNarrow ? 17.sp : 19.sp;

    return ListenableBuilder(
      listenable: _selectedIndex,
      builder: (context, _) {
        final selectedText =
            (options.isNotEmpty && _selectedIndex.value < options.length)
                ? options[_selectedIndex.value]
                : null;

        return Container(
          key: const ValueKey('modal_context_card'),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 20.h,
          ),
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: baseFontSize,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.55,
              ),
              children: _buildSentenceWithBlank(
                template,
                selectedText,
                primaryColor,
                isDark,
                baseFontSize,
              ),
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(
    GrammarQuest quest,
    Color primaryColor,
    double horizontalMargin,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: ScaleButton(
        key: const ValueKey('lock_configuration_button'),
        onTap: () => _submitAnswer(quest.correctAnswerIndex ?? 0, quest),
        child: Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 19.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "Confirm Selection",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onQuestionReset() {
    _scrollTimer?.cancel();
    _selectedIndex.value = 0;
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
        final options = quest?.options ?? ["CAN", "COULD", "MUST", "SHOULD"];
        final ruleText = quest?.grammarRule ?? quest?.ruleExplanation;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final isCompact = constraints.maxHeight < 650;
            final horizontalMargin = isNarrow ? 14.w : 22.w;

            return ListenableBuilder(
              listenable: Listenable.merge([
                isAnsweredNotifier,
                isCorrectNotifier,
                showConfettiNotifier,
              ]),
              builder: (context, _) {
                final isAnswered = isAnsweredNotifier.value ||
                    (state is GrammarLoaded &&
                        state.answerStatus != AnswerStatus.unanswered);
                final isCorrect = (isCorrectNotifier.value == true) ||
                    (state is GrammarLoaded &&
                        state.answerStatus == AnswerStatus.correct);

                return GrammarBaseLayout(
                  disablePadding: true,
                  gameType: widget.gameType,
                  level: widget.level,
                  isAnswered: isAnswered,
                  isCorrect: isCorrect,
                  isFinalFailure:
                      state is GrammarLoaded && state.isFinalFailure,
                  showConfetti: showConfettiNotifier.value,
                  useScrolling: false, // Using our own CustomScrollView
                  onContinue: () =>
                      context.read<GrammarBloc>().add(const NextQuestion()),
                  onHint: () {},
                  child: quest == null
                      ? GameShimmerLoading(primaryColor: theme.primaryColor)
                      : Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor:
                                  theme.primaryColor.withValues(alpha: 0.5),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              crossAxisMargin: 2,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverPadding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isCompact ? 12.h : 20.h,
                                    ),
                                    sliver: SliverList(
                                      delegate: SliverChildListDelegate([
                                        ModalsSelectionInstruction(
                                          primaryColor: theme.primaryColor,
                                          instruction: quest.instruction,
                                          horizontalMargin: horizontalMargin,
                                        ),
                                        SizedBox(
                                          height: isCompact ? 12.h : 20.h,
                                        ),

                                        if (ruleText != null &&
                                            ruleText.isNotEmpty) ...[
                                          _buildGrammarRule(
                                            ruleText,
                                            theme.primaryColor,
                                            isDark,
                                            horizontalMargin,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 12.h : 20.h,
                                          ),
                                        ],

                                        _buildContextCard(
                                          quest,
                                          options,
                                          theme.primaryColor,
                                          isDark,
                                          horizontalMargin,
                                          isNarrow,
                                        ),

                                        SizedBox(
                                          height: isCompact ? 18.h : 28.h,
                                        ),

                                        Center(
                                          child: ModalsRotaryDial(
                                            options: options,
                                            isAnsweredNotifier:
                                                isAnsweredNotifier,
                                            pendingJigsawNotifier:
                                                _pendingJigsaw,
                                            selectedIndexNotifier:
                                                _selectedIndex,
                                            correctAnswerIndex:
                                                quest.correctAnswerIndex ?? 0,
                                            isDark: isDark,
                                            primaryColor: theme.primaryColor,
                                          ),
                                        ),

                                        SizedBox(
                                          height: isCompact ? 18.h : 28.h,
                                        ),

                                        ListenableBuilder(
                                          listenable: Listenable.merge([
                                            isAnsweredNotifier,
                                            _pendingJigsaw,
                                          ]),
                                          builder: (context, _) {
                                            if (!isAnswered &&
                                                !_pendingJigsaw.value) {
                                              return _buildSubmitButton(
                                                quest,
                                                theme.primaryColor,
                                                horizontalMargin,
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ]),
                                    ),
                                  ),
                                  ListenableBuilder(
                                    listenable: Listenable.merge([
                                      _pendingJigsaw,
                                      isAnsweredNotifier,
                                    ]),
                                    builder: (context, _) {
                                      if (_pendingJigsaw.value && !isAnswered) {
                                        final sentence =
                                            quest.sentenceWithBlank ??
                                            quest.question ??
                                            quest.sentence ??
                                            "";
                                        String fullSentence = sentence;
                                        if (sentence.contains(
                                            RegExp(r'_{3,}'))) {
                                          fullSentence = sentence.replaceFirst(
                                            RegExp(r'_{3,}'),
                                            options[_selectedIndex.value],
                                          );
                                        } else if (quest.sentence != null &&
                                            quest.sentence!.isNotEmpty) {
                                          fullSentence = quest.sentence!;
                                        }
                                        final cleanTargetSentence =
                                            fullSentence
                                                .replaceAll(
                                                  RegExp(r'\s+'),
                                                  ' ',
                                                )
                                                .trim();

                                        if (cleanTargetSentence.isNotEmpty) {
                                          return SliverToBoxAdapter(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: horizontalMargin,
                                                vertical: 12.h,
                                              ),
                                              child: TypeToConfirmOverlay(
                                                expectedText:
                                                    cleanTargetSentence,
                                                displayText:
                                                    cleanTargetSentence,
                                                title: "Type to confirm",
                                                subtitle:
                                                    "Type the complete sentence to finish",
                                                primaryColor:
                                                    theme.primaryColor,
                                                onConfirmed: () =>
                                                    _submitFinalAnswer(
                                                      true,
                                                      quest,
                                                    ),
                                                onSkipped: () =>
                                                    _submitFinalAnswer(
                                                      false,
                                                      quest,
                                                    ),
                                                isPositioned: false,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                      return const SliverToBoxAdapter(
                                        child: SizedBox.shrink(),
                                      );
                                    },
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom >
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
                        ),
                );
              },
            );
          },
        );
      },
    );
  }
}
