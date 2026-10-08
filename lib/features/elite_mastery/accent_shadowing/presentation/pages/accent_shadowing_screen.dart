import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/layout/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import '../../../presentation/widgets/elite_feedback_card.dart';

import '../widgets/accent_shadowing_target_panel.dart';
import '../widgets/accent_shadowing_options_panel.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_self_evaluation_panel.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/elite_mastery/presentation/mixins/elite_mastery_game_screen_mixin.dart';

class AccentShadowingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AccentShadowingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.accentShadowing,
  });

  @override
  State<AccentShadowingScreen> createState() => _AccentShadowingScreenState();
}

class _AccentShadowingScreenState extends State<AccentShadowingScreen>
    with
        GameScreenMixin<AccentShadowingScreen>,
        EliteMasteryGameScreenMixin<AccentShadowingScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _attempts = ValueNotifier(0);
  final ValueNotifier<Set<int>> _matchedIndices = ValueNotifier({});

  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
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
    _attempts.dispose();
    _matchedIndices.dispose();
    _shuffledOptions.dispose();
    _originalIndices.dispose();
    _selectedIndex.dispose();
    _wrongIndices.dispose();
    _scrollController.dispose();
    disposeEliteMasteryGame();
    super.dispose();
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      _matchedIndices.value = Set.from(
        Iterable.generate(100),
      ); // Highlight all on success
      hapticService.success();
      soundService.playCorrect();
      context.read<EliteMasteryBloc>().add(const EliteSpeakConfirmed(5));
      context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(true));
    } else {
      submitWrongAnswer(quest: quest, userAnswer: 'Needs Practice');
    }
  }

  void _initializeOptionsIfNeeded(GameQuest? quest) {
    if (quest == null || quest.options == null || quest.options!.isEmpty) {
      return;
    }
    if (_shuffledOptions.value.isEmpty) {
      final options = List<String>.from(quest.options!);
      final indices = List<int>.generate(options.length, (i) => i);
      final combined = List.generate(
        options.length,
        (i) => (options[i], indices[i]),
      );
      combined.shuffle();

      _shuffledOptions.value = combined.map((e) => e.$1).toList();
      _originalIndices.value = combined.map((e) => e.$2).toList();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onOptionSelected(int shuffledIndex, GameQuest quest) {
    if (isAnsweredNotifier.value ||
        _wrongIndices.value.contains(shuffledIndex)) {
      return;
    }
    _selectedIndex.value = shuffledIndex;

    final originalIndex = _originalIndices.value[shuffledIndex];
    final isCorrect = originalIndex == quest.correctAnswerIndex;

    if (isCorrect) {
      isFirstStagePassedNotifier.value = true;
      hapticService.selection();
      soundService.playClick();
      _scrollToBottom();
    } else {
      _scrollToBottom();
      final userAnswer = _shuffledOptions.value.length > shuffledIndex
          ? _shuffledOptions.value[shuffledIndex]
          : 'Unknown';
      _attempts.value++;
      _wrongIndices.value = [..._wrongIndices.value, shuffledIndex];
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  @override
  void onQuestionReset() {
    isFirstStagePassedNotifier.value = false;
    _attempts.value = 0;
    _matchedIndices.value = {};
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
        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
            _attempts,
            _matchedIndices,
          ]),
          builder: (context, _) {
            return EliteBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              state: state,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure:
                  (state is EliteMasteryLoaded && state.isFinalFailure) ||
                  (state is EliteMasteryLoaded
                      ? state.livesRemaining <= 0
                      : false),
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              disablePadding: true,
              fullScreenContent: true,
              onContinue: () {
                isAnsweredNotifier.value = false;
                isFirstStagePassedNotifier.value = false;
                isCorrectNotifier.value = null;
                _attempts.value = 0;
                _matchedIndices.value = {};
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

  Widget _buildGameUI(
    BuildContext context,
    EliteMasteryLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final targetText = quest.text ?? quest.textToSpeak;

    return Stack(
      children: [
        RawScrollbar(
          controller: _scrollController,
          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
          radius: Radius.circular(8.r),
          thickness: 4.w,
          crossAxisMargin: 4.w,
          mainAxisMargin: 16.h,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final isCompact =
                        MediaQuery.of(context).size.height <
                        _kCompactHeightBreakpoint;
                    return IgnorePointer(
                      ignoring:
                          isFirstStagePassedNotifier.value ||
                          isAnsweredNotifier.value,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: isCompact ? 5.h : 10.h,
                        ),
                        child: Column(
                          children: [
                            if (quest.instruction.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 16.h,
                                ),
                                margin: EdgeInsets.only(bottom: 24.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [
                                            theme.primaryColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            theme.primaryColor.withValues(
                                              alpha: 0.05,
                                            ),
                                          ]
                                        : [
                                            theme.primaryColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            Colors.white,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline_rounded,
                                      color: theme.primaryColor,
                                      size: 24.r,
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        quest.instruction,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.slate800,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            AccentShadowingTargetPanel(
                              text:
                                  targetText ??
                                  context.tr(
                                    'games.target_text_fallback',
                                    fallback: 'Target Text',
                                  ),
                              matchedIndices: _matchedIndices.value,
                              isDark: isDark,
                              primaryColor: theme.primaryColor,
                              isAnswered: isAnsweredNotifier.value,
                              isCorrect: isCorrectNotifier.value,
                              attempts: _attempts.value,
                              onListenTap: () => soundService.playTts(
                                targetText ?? "",
                                speed: quest.speedMultiplier ?? 0.4,
                              ),
                            ),

                            if (state.isHintVisible) ...[
                              SizedBox(height: isCompact ? 12.h : 20.h),
                              EliteHintCard(
                                hintText: quest.hint,
                                isVisible: true,
                                onShowHint: () {},
                                primaryColor: theme.primaryColor,
                              ),
                            ],
                            SizedBox(height: isCompact ? 16.h : 30.h),

                            if (quest.options != null &&
                                quest.options!.isNotEmpty)
                              ListenableBuilder(
                                listenable: Listenable.merge([
                                  _shuffledOptions,
                                  _originalIndices,
                                  _selectedIndex,
                                  _wrongIndices,
                                ]),
                                builder: (context, _) {
                                  return AccentShadowingOptionsPanel(
                                    shuffledOptions: _shuffledOptions.value,
                                    originalIndices: _originalIndices.value,
                                    selectedIndex: _selectedIndex.value,
                                    wrongIndices: _wrongIndices.value,
                                    isAnswered:
                                        isFirstStagePassedNotifier.value ||
                                        isAnsweredNotifier.value,
                                    showCorrectAnswer:
                                        isFirstStagePassedNotifier.value ||
                                        isAnsweredNotifier.value,
                                    correctAnswerIndex:
                                        quest.correctAnswerIndex ?? 0,
                                    isDark: isDark,
                                    primaryColor: theme.primaryColor,
                                    onOptionSelected: (index) =>
                                        _onOptionSelected(index, quest),
                                  );
                                },
                              )
                            else if (!isAnsweredNotifier.value)
                              AccentSelfEvaluationPanel(
                                textToSpeak: "", // Removed duplicate text
                                primaryColor: theme.primaryColor,
                                isCompact: isCompact,
                                onEvaluate: (nailedIt) =>
                                    _submitVerbalEvaluation(nailedIt, quest),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isFirstStagePassedNotifier.value && !isAnsweredNotifier.value)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24.h, bottom: 24.h),
                    child: SpeakToConfirmOverlay(
                      expectedText: targetText ?? "",
                      displayText: targetText ?? "",
                      title: 'SPEAK TO SHADOW',
                      subtitle: 'Shadow the native pronunciation',
                      displayFontSize: 16.sp,
                      displayFontWeight: FontWeight.w500,
                      displayTextAlign: TextAlign.center,
                      primaryColor: theme.primaryColor,
                      isPositioned: false,
                      onConfirmed: () => _submitVerbalEvaluation(true, quest),
                      onSkipped: () => _submitVerbalEvaluation(false, quest),
                    ),
                  ),
                ),
              if (isFirstStagePassedNotifier.value &&
                  !isAnsweredNotifier.value)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: EliteFeedbackCard(
                      state: state,
                      isCorrect: true,
                      onContinue: null,
                      isDark: isDark,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: isAnsweredNotifier.value ? 400.h : 60.h,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
