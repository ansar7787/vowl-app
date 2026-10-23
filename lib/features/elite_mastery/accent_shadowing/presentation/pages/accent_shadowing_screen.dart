import 'dart:async';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/layout/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';

import '../widgets/accent_shadowing_target_panel.dart';
import '../widgets/accent_shadowing_options_panel.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_self_evaluation_panel.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/elite_mastery/presentation/mixins/elite_mastery_game_screen_mixin.dart';
import 'package:vowl/features/elite_mastery/domain/entities/elite_mastery_quest.dart';

/// Interactive speech practice screen where users shadow native accent cadences and nuances.
class AccentShadowingScreen extends StatefulWidget {
  /// Target curriculum level number.
  final int level;

  /// Subgame game type identifier.
  final GameSubtype gameType;

  /// Creates an [AccentShadowingScreen] for [level] and [gameType].
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
  Timer? _scrollTimer;

  static const double _kCompactHeightBreakpoint = 580;

  @override
  void initState() {
    super.initState();
    initEliteMasteryGame();
    final initial = context.read<EliteMasteryBloc>().state;
    if (initial is EliteMasteryLoaded && initial.quests.isNotEmpty) {
      _initializeOptionsIfNeeded(initial.currentQuest);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
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
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
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
        final bool isAnswered =
            (state is EliteMasteryLoaded && state.answerStatus.isAnswered) ||
            isAnsweredNotifier.value;
        final bool? isCorrect = state is EliteMasteryLoaded
            ? (state.answerStatus.asBoolOrNull ?? isCorrectNotifier.value)
            : isCorrectNotifier.value;

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
              isAnswered: isAnswered,
              state: state,
              isCorrect: isCorrect,
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
              onHint: () {},
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
      if (state.quests.isEmpty) return const SizedBox.shrink();
      return _buildGameUI(context, state, isDark, theme);
    }
    if (state is EliteMasteryGameOver) {
      if (state.quests.isEmpty) return const SizedBox.shrink();
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
    if (state is EliteMasteryLoaded && state.quests.isNotEmpty) {
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
            key: const Key('accent_shadowing_scroll_view'),
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
                                key: const Key('accent_shadowing_instruction_banner'),
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18.w,
                                  vertical: 12.h,
                                ),
                                margin: EdgeInsets.only(bottom: 16.h),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.slate800
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: isDark
                                        ? theme.primaryColor.withValues(
                                            alpha: 0.25,
                                          )
                                        : theme.primaryColor.withValues(
                                            alpha: 0.15,
                                          ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.15)
                                          : theme.primaryColor.withValues(
                                              alpha: 0.04,
                                            ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  quest.instruction,
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: isCompact ? 13.sp : 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.95)
                                        : AppColors.slate800,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                            AccentShadowingTargetPanel(
                              text:
                                  targetText ??
                                  context.tr(
                                    'games.target_text_fallback',
                                    fallback: 'Listen and repeat the phrase.',
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
                  child: AccentShadowingInsightsPanel(
                    key: const Key('accent_shadowing_insights_panel'),
                    quest: quest,
                    isDark: isDark,
                    primaryColor: theme.primaryColor,
                  ),
                ),
              if (isFirstStagePassedNotifier.value && !isAnsweredNotifier.value)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    child: SpeakToConfirmOverlay(
                      expectedText: targetText ?? "",
                      displayText: targetText ?? "",
                      title: 'SPEAK TO SHADOW',
                      subtitle: 'Speak naturally and match what you heard',
                      displayFontSize: 16.sp,
                      displayFontWeight: FontWeight.w600,
                      displayTextAlign: TextAlign.center,
                      primaryColor: theme.primaryColor,
                      isPositioned: false,
                      onConfirmed: () => _submitVerbalEvaluation(true, quest),
                      onSkipped: () => _submitVerbalEvaluation(false, quest),
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

/// Renders pedagogical explanations, shadowing focal points, and accent nuances.
class AccentShadowingInsightsPanel extends StatelessWidget {
  /// The active quest data furnishing the pedagogical feedback.
  final EliteMasteryQuest quest;

  /// Whether dark mode styling is active.
  final bool isDark;

  /// The primary thematic accent color.
  final Color primaryColor;

  /// Creates an [AccentShadowingInsightsPanel] widget.
  const AccentShadowingInsightsPanel({
    super.key,
    required this.quest,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasInsights =
        quest.explanation != null ||
        quest.shadowingFocus != null ||
        quest.targetAccent != null ||
        quest.usageContext != null ||
        quest.spellingRule != null ||
        quest.sequenceLogic != null;

    if (!hasInsights) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: primaryColor,
                size: 22.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Pronunciation Notes',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (quest.targetAccent != null)
            _buildInsightRow(
              context,
              icon: Icons.record_voice_over_rounded,
              label: 'Target Sound',
              value: quest.targetAccent!,
            ),
          if (quest.shadowingFocus != null)
            _buildInsightRow(
              context,
              icon: Icons.rule_rounded,
              label: 'Sound Pattern',
              value: quest.shadowingFocus!,
            ),
          if (quest.usageContext != null)
            _buildInsightRow(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Everyday Context',
              value: quest.usageContext!,
            ),
          if (quest.spellingRule != null)
            _buildInsightRow(
              context,
              icon: Icons.spellcheck_rounded,
              label: 'Spelling Note',
              value: quest.spellingRule!,
            ),
          if (quest.sequenceLogic != null)
            _buildInsightRow(
              context,
              icon: Icons.low_priority_rounded,
              label: 'Speech Flow',
              value: quest.sequenceLogic!,
            ),
          if (quest.explanation != null)
            _buildInsightRow(
              context,
              icon: Icons.menu_book_rounded,
              label: 'Explanation',
              value: quest.explanation!,
            ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor.withValues(alpha: 0.7), size: 18.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.slate700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
