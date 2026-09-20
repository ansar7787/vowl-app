import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/layout/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import '../widgets/idiom_match_options_panel.dart';
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
    with EliteMasteryGameScreenMixin {
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
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
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
    });

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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onOptionSelected(int shuffledIndex, int? correctOriginalIndex) {
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
      hapticService.error();
      soundService.playWrong();

      if (!_wrongIndices.value.contains(shuffledIndex)) {
        final newWrong = List<int>.from(_wrongIndices.value);
        newWrong.add(shuffledIndex);
        _wrongIndices.value = newWrong;
      }
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _selectedIndex.value = shuffledIndex;

      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<EliteMasteryBloc>().add(const EliteSpeakConfirmed(5));
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(false));
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
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
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
            _selectedIndex,
            _shuffledOptions,
            _originalIndices,
            _wrongIndices,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            final expectedText = quest != null && _selectedIndex.value != null
                ? _shuffledOptions.value[_selectedIndex.value!]
                : "";

            String contextSentence = expectedText;
            if (quest?.explanation != null &&
                quest!.explanation!.contains("Example: '")) {
              final parts = quest.explanation!.split("Example: '");
              if (parts.length > 1) {
                contextSentence = parts[1].split("'").first;
              }
            }

            debugPrint(contextSentence);

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
              visualConfig: quest?.visualConfig,
              onContinue: () {
                isAnsweredNotifier.value = false;
                isCorrectNotifier.value = null;
                _selectedIndex.value = null;
                _wrongIndices.value = [];
                isFirstStagePassedNotifier.value = false;
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
              child: _buildBody(context, state, isDark, theme, expectedText),
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
    String expectedText,
  ) {
    if (state is EliteMasteryLoaded) {
      return _buildGameUI(context, state, isDark, theme, expectedText);
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
            expectedText,
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
    String expectedText,
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
                physics: (!isFirstStagePassedNotifier.value)
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: IgnorePointer(
                      ignoring: isFirstStagePassedNotifier.value,
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

                                return Column(
                                  children: [
                                    if (quest.question != null &&
                                        quest.question!.isNotEmpty) ...[
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                        ),
                                        child: Container(
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
                                                size: 32.r,
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                quest.question!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: isCompact
                                                      ? 16.sp
                                                      : 18.sp,
                                                  fontWeight: FontWeight.w600,
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
                                      ),
                                    ],
                                    if (state.isHintVisible) ...[
                                      SizedBox(height: isCompact ? 12.h : 20.h),
                                      EliteHintCard(
                                        hintText: quest.hint,
                                        isVisible: true,
                                        onShowHint: () {},
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ],
                                    SizedBox(height: isCompact ? 16.h : 24.h),
                                    IdiomMatchOptionsPanel(
                                      shuffledOptions: _shuffledOptions.value,
                                      originalIndices: _originalIndices.value,
                                      selectedIndex: _selectedIndex.value,
                                      wrongIndices: _wrongIndices.value,
                                      isAnswered:
                                          isAnsweredNotifier.value ||
                                          isFirstStagePassedNotifier.value,
                                      showCorrectAnswer:
                                          isCorrectNotifier.value == true ||
                                          isFirstStagePassedNotifier.value,
                                      correctAnswerIndex:
                                          quest.correctAnswerIndex ?? 0,
                                      isDark: isDark,
                                      primaryColor: theme.primaryColor,
                                      onOptionSelected: (index) =>
                                          _onOptionSelected(
                                            index,
                                            quest.correctAnswerIndex,
                                          ),
                                    ),
                                    if ((isFirstStagePassedNotifier.value ||
                                            isAnsweredNotifier.value) &&
                                        quest.idiomOrigin != null) ...[
                                      SizedBox(height: 24.h),
                                      Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(20.r),
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                            ),
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
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.history_edu_rounded,
                                                      color: Colors.blueAccent,
                                                      size: 20.r,
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Text(
                                                      "IDIOM ORIGIN",
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  quest.idiomOrigin!,
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 14.sp,
                                                    color: isDark
                                                        ? Colors.white70
                                                        : Colors.black87,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                SizedBox(height: 16.h),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.visibility_rounded,
                                                      color:
                                                          Colors.purpleAccent,
                                                      size: 20.r,
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Text(
                                                      "VISUAL METAPHOR",
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.purpleAccent,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  quest.visualMetaphor ?? "",
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 14.sp,
                                                    color: isDark
                                                        ? Colors.white70
                                                        : Colors.black87,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .animate()
                                          .fadeIn(duration: 400.ms)
                                          .slideY(begin: 0.1),
                                    ],
                                  ],
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
                          SpeakToConfirmOverlay(
                            expectedText: expectedText,
                            displayText:
                                "Speak the idiom in context:\n\n\"$expectedText\"",
                            primaryColor: theme.primaryColor,
                            isPositioned: false,
                            onConfirmed: () => _submitVerbalEvaluation(true),
                            onSkipped: () => _submitVerbalEvaluation(false),
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
}
