import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../../../domain/entities/elite_mastery_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/layout/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import '../widgets/idiom_match_options_panel.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/elite_mastery/presentation/mixins/elite_mastery_game_screen_mixin.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color1a1a2e = Color(0xFF1A1A2E);
}

class IdiomMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const IdiomMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.idiomMatch,
  });

  @override
  State<IdiomMatchScreen> createState() => _IdiomMatchScreenState();
}

class _IdiomMatchScreenState extends State<IdiomMatchScreen>
    with
        GameScreenMixin<IdiomMatchScreen>,
        EliteMasteryGameScreenMixin<IdiomMatchScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<List<int>> _originalIndices = ValueNotifier([]);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<List<int>> _wrongIndices = ValueNotifier([]);

  static const double _kCompactHeightBreakpoint = 580;

  @override
  void initState() {
    super.initState();
    initEliteMasteryGame();
  }

  @override
  void dispose() {
    _shuffledOptions.dispose();
    _originalIndices.dispose();
    _selectedIndex.dispose();
    _wrongIndices.dispose();
    _scrollController.dispose();
    disposeEliteMasteryGame();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onOptionSelected(
    EliteMasteryQuest quest,
    int shuffledIndex,
    int? correctOriginalIndex,
  ) {
    if (isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        _wrongIndices.value.contains(shuffledIndex)) {
      return;
    }

    final actualOriginalIndex = _originalIndices.value[shuffledIndex];
    final isCorrect = actualOriginalIndex == correctOriginalIndex;

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      _selectedIndex.value = shuffledIndex;
      // Do NOT submit yet! Wait for Phase 2.
    } else {
      _scrollToBottom();
      if (!_wrongIndices.value.contains(shuffledIndex)) {
        final newWrong = List<int>.from(_wrongIndices.value);
        newWrong.add(shuffledIndex);
        _wrongIndices.value = newWrong;
      }
      _selectedIndex.value = shuffledIndex;

      final userAnswer = _shuffledOptions.value.length > shuffledIndex
          ? _shuffledOptions.value[shuffledIndex]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, EliteMasteryQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      hapticService.success();
      soundService.playCorrect();
      context.read<EliteMasteryBloc>().add(const EliteSpeakConfirmed(5));
      context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(true));
    } else {
      final expectedText =
          quest.options != null &&
              _selectedIndex.value != null &&
              _shuffledOptions.value.length > _selectedIndex.value!
          ? _shuffledOptions.value[_selectedIndex.value!]
          : "";
      submitWrongAnswer(
        quest: quest.copyWith(
          question: "Speak the idiom aloud",
          correctAnswer: expectedText,
        ),
        userAnswer: '[Skipped speaking]',
      );
    }
  }

  void _initializeOptionsIfNeeded(EliteMasteryQuest? quest) {
    if (quest == null || quest.options == null || quest.options!.isEmpty)
      return;
    if (_shuffledOptions.value.isEmpty) {
      final options = List<String>.from(quest.options!);
      final indices = List<int>.generate(options.length, (i) => i);
      final combined = List.generate(
        options.length,
        (i) => (options[i], indices[i]),
      );
      combined.shuffle();

      // We must not call setState or modify notifiers during build without post frame if this was called from build,
      // but onEliteMasteryStateChanged is a listener, so it's safe to update notifiers directly.
      _shuffledOptions.value = combined.map((e) => e.$1).toList();
      _originalIndices.value = combined.map((e) => e.$2).toList();
    }
  }

  @override
  void onEliteMasteryStateChanged(
    BuildContext context,
    EliteMasteryState state,
  ) {
    super.onEliteMasteryStateChanged(context, state);
    if (state is EliteMasteryLoaded) {
      _initializeOptionsIfNeeded(state.currentQuest);
    }
  }

  @override
  void onQuestionReset() {
    _shuffledOptions.value = [];
    _originalIndices.value = [];
    _selectedIndex.value = null;
    _wrongIndices.value = [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        (Theme.of(context).brightness == Brightness.dark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black);
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      level: widget.level,
      isDark: isDark,
      isMidnight: isMidnight,
    );

    return BlocConsumer<EliteMasteryBloc, EliteMasteryState>(
      listenWhen: eliteMasteryListenWhen,
      listener: onEliteMasteryStateChanged,
      builder: (context, state) {
        final quest = (state is EliteMasteryLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            return EliteBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              state: state,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: (state is EliteMasteryLoaded)
                  ? (state.isFinalFailure || state.livesRemaining <= 0)
                  : false,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              disablePadding: true,
              fullScreenContent: true,
              visualConfig: quest?.visualConfig,
              onContinue: () {
                isAnsweredNotifier.value = false;
                isCorrectNotifier.value = null;
                isFirstStagePassedNotifier.value = false;
                onQuestionReset();
                context.read<EliteMasteryBloc>().add(NextEliteQuestion());
              },
              onHint: () {
                final bloc = context.read<EliteMasteryBloc>();
                final s = bloc.state;
                if (s is EliteMasteryLoaded) {
                  if (s.currentQuest.hint != null &&
                      s.currentQuest.hint!.isNotEmpty) {
                    if (!s.isHintUsed) bloc.add(MarkEliteHintUsed());
                    bloc.add(ShowEliteHint());
                  } else {
                    GameDialogHelper.showHintAdDialog(
                      context,
                      onHintEarned: () {
                        if (!s.isHintUsed) bloc.add(MarkEliteHintUsed());
                        bloc.add(ShowEliteHint());
                      },
                    );
                  }
                }
              },
              child: _buildBody(context, state, isDark, theme),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    EliteMasteryState state,
    bool isDark,
    ThemeResult theme,
  ) {
    if (state is EliteMasteryLoaded) {
      return _buildGameUI(context, state, isDark, theme);
    }
    if (state is EliteMasteryGameOver) {
      return Opacity(
        opacity: 0.5,
        child: AbsorbPointer(
          child: _buildGameUI(
            context,
            EliteMasteryLoaded(
              quests: state.quests,
              currentIndex: state.currentIndex,
              livesRemaining: 0,
            ),
            isDark,
            theme,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGameUI(
    BuildContext context,
    EliteMasteryLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, outerConstraints) {
            return RawScrollbar(
              controller: _scrollController,
              thumbColor: theme.primaryColor.withValues(alpha: 0.5),
              radius: Radius.circular(8.r),
              thickness: 4.w,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  SliverToBoxAdapter(
                    child: IgnorePointer(
                      ignoring:
                          isFirstStagePassedNotifier.value ||
                          isAnsweredNotifier.value,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: outerConstraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact =
                                    constraints.maxHeight <
                                    _kCompactHeightBreakpoint;

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: Column(
                                    children: [
                                      if (quest.instruction.isNotEmpty) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 12.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.08,
                                                  )
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.grey.withValues(
                                                      alpha: 0.2,
                                                    ),
                                            ),
                                            boxShadow: isDark
                                                ? []
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.03,
                                                          ),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                          ),
                                          child: Text(
                                            quest.instruction,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: isCompact
                                                  ? 12.sp
                                                  : 13.sp,
                                              fontWeight: FontWeight.w400,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                      ],
                                      if (quest.question != null &&
                                          quest.question!.isNotEmpty) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(24.r),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              24.r,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isDark
                                                  ? [
                                                      Colors.white.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                      Colors.white.withValues(
                                                        alpha: 0.02,
                                                      ),
                                                    ]
                                                  : [
                                                      Colors.white,
                                                      Colors.white.withValues(
                                                        alpha: 0.7,
                                                      ),
                                                    ],
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.15,
                                                    )
                                                  : theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              if (!isDark)
                                                BoxShadow(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 12),
                                                ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.format_quote_rounded,
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.6),
                                                size: 24.r,
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                quest.question!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: isCompact
                                                      ? 15.sp
                                                      : 16.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppColors.slate900,
                                                  height: 1.4,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (state.isHintVisible) ...[
                                        SizedBox(
                                          height: isCompact ? 12.h : 20.h,
                                        ),
                                        EliteHintCard(
                                          hintText: quest.hint,
                                          isVisible: true,
                                          onShowHint: () {},
                                          primaryColor: theme.primaryColor,
                                        ),
                                      ],
                                      SizedBox(height: isCompact ? 16.h : 24.h),
                                      ListenableBuilder(
                                        listenable: Listenable.merge([
                                          _selectedIndex,
                                          _shuffledOptions,
                                          _originalIndices,
                                          _wrongIndices,
                                        ]),
                                        builder: (context, _) {
                                          return IdiomMatchOptionsPanel(
                                            shuffledOptions:
                                                _shuffledOptions.value,
                                            originalIndices:
                                                _originalIndices.value,
                                            selectedIndex: _selectedIndex.value,
                                            wrongIndices: _wrongIndices.value,
                                            isAnswered:
                                                isAnsweredNotifier.value ||
                                                isFirstStagePassedNotifier
                                                    .value,
                                            showCorrectAnswer:
                                                isAnsweredNotifier.value ||
                                                isFirstStagePassedNotifier
                                                    .value,
                                            correctAnswerIndex:
                                                quest.correctAnswerIndex ?? 0,
                                            isDark: isDark,
                                            primaryColor: theme.primaryColor,
                                            onOptionSelected: (index) =>
                                                _onOptionSelected(
                                                  quest,
                                                  index,
                                                  quest.correctAnswerIndex,
                                                ),
                                          );
                                        },
                                      ),
                                      if ((isFirstStagePassedNotifier.value ||
                                              isAnsweredNotifier.value) &&
                                          (quest.explanation != null ||
                                              quest.usageContext != null ||
                                              quest.idiomOrigin != null ||
                                              quest.visualMetaphor !=
                                                  null)) ...[
                                        SizedBox(height: 24.h),
                                        Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.all(20.r),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? _LocalPalette.color1a1a2e
                                                    : Colors.blue.withValues(
                                                        alpha: 0.05,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(20.r),
                                                border: Border.all(
                                                  color: Colors.blueAccent
                                                      .withValues(alpha: 0.3),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (quest.explanation != null)
                                                    _buildFeedbackItem(
                                                      context,
                                                      "EXPLANATION",
                                                      quest.explanation!,
                                                      Icons
                                                          .lightbulb_outline_rounded,
                                                      Colors.orangeAccent,
                                                      isDark,
                                                    ),
                                                  if (quest.usageContext !=
                                                      null)
                                                    _buildFeedbackItem(
                                                      context,
                                                      "USAGE CONTEXT",
                                                      quest.usageContext!,
                                                      Icons
                                                          .chat_bubble_outline_rounded,
                                                      Colors
                                                          .tealAccent
                                                          .shade400,
                                                      isDark,
                                                    ),
                                                  if (quest.idiomOrigin != null)
                                                    _buildFeedbackItem(
                                                      context,
                                                      "IDIOM ORIGIN",
                                                      quest.idiomOrigin!,
                                                      Icons.history_edu_rounded,
                                                      Colors.blueAccent,
                                                      isDark,
                                                    ),
                                                  if (quest.visualMetaphor !=
                                                      null)
                                                    _buildFeedbackItem(
                                                      context,
                                                      "VISUAL METAPHOR",
                                                      quest.visualMetaphor!,
                                                      Icons.visibility_rounded,
                                                      Colors.purpleAccent,
                                                      isDark,
                                                    ),
                                                ],
                                              ),
                                            )
                                            .animate()
                                            .fadeIn(duration: 400.ms)
                                            .slideY(begin: 0.1),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          (isAnsweredNotifier.value ||
                              isFirstStagePassedNotifier.value)
                          ? 180.h
                          : 60.h,
                    ),
                  ),
                  if (isFirstStagePassedNotifier.value &&
                      !isAnsweredNotifier.value)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          ListenableBuilder(
                            listenable: Listenable.merge([
                              _selectedIndex,
                              _shuffledOptions,
                            ]),
                            builder: (context, _) {
                              final expectedText =
                                  quest.options != null &&
                                      _selectedIndex.value != null &&
                                      _shuffledOptions.value.length >
                                          _selectedIndex.value!
                                  ? _shuffledOptions.value[_selectedIndex
                                        .value!]
                                  : "";
                              return SpeakToConfirmOverlay(
                                expectedText: expectedText,
                                displayText: expectedText,
                                title: 'SPEAK THE IDIOM',
                                subtitle: 'Say the idiom aloud to confirm',
                                displayFontSize: 16.sp,
                                displayFontWeight: FontWeight.w500,
                                displayTextAlign: TextAlign.center,
                                primaryColor: theme.primaryColor,
                                isPositioned: false,
                                onConfirmed: () =>
                                    _submitVerbalEvaluation(true, quest),
                                onSkipped: () =>
                                    _submitVerbalEvaluation(false, quest),
                              );
                            },
                          ),
                          SizedBox(height: 60.h),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeedbackItem(
    BuildContext context,
    String title,
    String? content,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
