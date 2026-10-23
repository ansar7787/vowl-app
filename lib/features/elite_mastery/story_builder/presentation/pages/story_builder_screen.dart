import '../../../domain/entities/elite_mastery_quest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';
import 'package:vowl/features/elite_mastery/presentation/mixins/elite_mastery_game_screen_mixin.dart';
import 'package:vowl/features/elite_mastery/presentation/layout/elite_base_layout.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_hint_card.dart';

import '../widgets/story_builder_narrative_tile.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

/// Story Builder game screen challenging players to arrange narrative segments into logical discourse sequence.
class StoryBuilderScreen extends StatefulWidget {
  /// Target curriculum difficulty level.
  final int level;

  /// Game subtype identifier.
  final GameSubtype gameType;

  /// Creates a [StoryBuilderScreen] for [level] and [gameType].
  const StoryBuilderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.storyBuilder,
  });

  @override
  State<StoryBuilderScreen> createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen>
    with
        GameScreenMixin<StoryBuilderScreen>,
        EliteMasteryGameScreenMixin<StoryBuilderScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<List<int>> _currentOrder = ValueNotifier([]);
  final ValueNotifier<int?> _selectedTileIndex = ValueNotifier(null);
  VisualConfig? _visualConfig;
  int _retryCount = 0;

  // Below this available height, use tighter spacing. See the identical
  // constant in accent_shadowing_screen.dart / idiom_match_screen.dart /
  // speed_spelling_screen.dart — worth consolidating into one shared
  // constant, noted in the review report's Refactoring Opportunities.
  static const double _kCompactHeightBreakpoint = 580;

  @override
  void initState() {
    super.initState();
    initEliteMasteryGame();
    final state = context.read<EliteMasteryBloc>().state;
    if (state is EliteMasteryLoaded) {
      if (state.currentQuest.sentences != null &&
          state.currentQuest.sentences!.isNotEmpty) {
        _currentOrder.value = List.generate(
          state.currentQuest.sentences!.length,
          (i) => i,
        );
      }
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
  }

  @override
  void dispose() {
    _currentOrder.dispose();
    _selectedTileIndex.dispose();
    _scrollController.dispose();
    disposeEliteMasteryGame();
    super.dispose();
  }

  void _onTileTap(int index) {
    if (isAnsweredNotifier.value) return;

    final currentSelected = _selectedTileIndex.value;
    if (currentSelected == null) {
      _selectedTileIndex.value = index;
    } else if (currentSelected == index) {
      _selectedTileIndex.value = null; // Toggle off
    } else {
      // Swap tiles
      isCorrectNotifier.value = null;
      final newOrder = List<int>.from(_currentOrder.value);
      final temp = newOrder[currentSelected];
      newOrder[currentSelected] = newOrder[index];
      newOrder[index] = temp;

      _currentOrder.value = newOrder;
      _selectedTileIndex.value = null;
      hapticService.selection();
    }
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

  void _onReorder(int oldIndex, int newIndex) {
    if (isAnsweredNotifier.value) return;
    isCorrectNotifier.value = null; // Clear feedback borders on move
    _selectedTileIndex.value = null; // Clear selection
    if (newIndex > oldIndex) newIndex -= 1;
    final newOrder = List<int>.from(_currentOrder.value);
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    _currentOrder.value = newOrder;
    hapticService.selection();
  }

  bool isCorrectNotifierSequence(List<int> current, List<int>? correctIndices) {
    if (correctIndices == null || current.length != correctIndices.length) {
      return false;
    }
    for (int i = 0; i < current.length; i++) {
      if (current[i] != correctIndices[i]) return false;
    }
    return true;
  }

  void _submitOrder(EliteMasteryQuest quest) {
    final correctOrder = quest.correctOrder;
    if (correctOrder == null ||
        isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value) {
      return;
    }

    bool isCorrect = isCorrectNotifierSequence(
      _currentOrder.value,
      correctOrder,
    );

    if (isCorrect) {
      hapticService.success();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
    } else {
      final userAnswer = quest.sentences != null
          ? _currentOrder.value
                .where((i) => i < quest.sentences!.length)
                .map((i) => quest.sentences![i])
                .join(' -> ')
          : _currentOrder.value.join(', ');

      final correctAnswer =
          (quest.sentences != null && quest.correctOrder != null)
          ? quest.correctOrder!
                .where((i) => i < quest.sentences!.length)
                .map((i) => quest.sentences![i])
                .join(' -> ')
          : '';

      submitWrongAnswer(
        quest: quest.copyWith(
          question: quest.instruction,
          correctAnswer: correctAnswer,
        ),
        userAnswer: userAnswer,
      );
    }
  }

  String _formatSequenceLogic(String logic) {
    final lower = logic.toLowerCase().trim();
    if (lower.contains('prerequisite')) return 'Step-by-step order';
    if (lower.contains('chronological')) return 'Time order';
    if (lower.contains('problem')) return 'Problem & solution';
    if (lower.contains('preparation')) return 'Step-by-step';
    if (lower.contains('attempt')) return 'Action & outcome';
    if (lower.contains('information')) return 'Action & outcome';
    if (lower.contains('discovery')) return 'Cause & effect';
    if (lower.contains('cause and effect')) return 'Cause & effect';
    return logic.replaceAll('->', '➔').replaceAll('→', '➔').trim();
  }

  void _submitVerbalEvaluation(bool nailedIt, EliteMasteryQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      hapticService.success();
      soundService.playCorrect();
      context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(true));
    } else {
      final expectedText =
          (quest.sentences != null &&
              quest.sentences!.isNotEmpty &&
              quest.correctOrder != null)
          ? quest.correctOrder!.map((i) => quest.sentences![i]).join(' ')
          : "Read the story aloud";

      submitWrongAnswer(
        quest: quest.copyWith(
          question: "Speak the story",
          correctAnswer: expectedText,
        ),
        userAnswer: '[Skipped speaking]',
      );
    }
  }

  @override
  void onQuestionReset() {
    _retryCount++;
    final state = context.read<EliteMasteryBloc>().state;
    _selectedTileIndex.value = null;
    if (state is EliteMasteryLoaded && state.currentQuest.sentences != null) {
      _currentOrder.value = List.generate(
        state.currentQuest.sentences!.length,
        (i) => i,
      );
    } else {
      _currentOrder.value = [];
    }
  }

  @override
  void onEliteMasteryStateChanged(
    BuildContext context,
    EliteMasteryState state,
  ) {
    super.onEliteMasteryStateChanged(context, state);
    if (state is EliteMasteryLoaded &&
        state.currentQuest.sentences != null &&
        _currentOrder.value.isEmpty) {
      _currentOrder.value = List.generate(
        state.currentQuest.sentences!.length,
        (i) => i,
      );
    }
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
          ]),
          builder: (context, _) {
            return EliteBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              state: state,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: (state is EliteMasteryLoaded)
                  ? (state.isFinalFailure || state.livesRemaining <= 0)
                  : false,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              disablePadding: true,
              fullScreenContent: true,
              visualConfig: _visualConfig,
              onContinue: () {
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
    // `EliteMasteryLoading` and `EliteMasteryError` are both handled
    // centrally by `EliteBaseLayout`: it renders its own shimmer/error UI
    // directly inside its Stack and never includes this `child` slot for
    // either state, so no local UI is built (or ever shown) for them here.
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

  Widget _buildGameUI(
    BuildContext context,
    EliteMasteryLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;

    if (_currentOrder.value.isEmpty &&
        quest.sentences != null &&
        quest.sentences!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentOrder.value.isEmpty) {
          _currentOrder.value = List.generate(
            quest.sentences!.length,
            (i) => i,
          );
        }
      });
    }

    return Stack(
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([_currentOrder, _selectedTileIndex]),
          builder: (context, _) {
            final currentOrder = _currentOrder.value.isNotEmpty
                ? _currentOrder.value
                : (quest.sentences != null
                    ? List.generate(quest.sentences!.length, (i) => i)
                    : const <int>[]);
            final selectedIndex = _selectedTileIndex.value;
            return RawScrollbar(
              controller: _scrollController,
              thumbColor: theme.primaryColor.withValues(alpha: 0.5),
              radius: Radius.circular(8.r),
              thickness: 4.w,
              child: CustomScrollView(
                key: const Key('story_builder_scroll_view'),
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                  SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact =
                            constraints.maxHeight < _kCompactHeightBreakpoint;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            children: [
                              if (state.isHintVisible) ...[
                                EliteHintCard(
                                  hintText: quest.hint,
                                  isVisible: true,
                                  onShowHint: () {},
                                  primaryColor: theme.primaryColor,
                                ),
                                SizedBox(height: isCompact ? 12.h : 20.h),
                              ],
                              if (quest.instruction.isNotEmpty) ...[
                                Container(
                                  key: const Key(
                                    'story_builder_instruction_banner',
                                  ),
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 14.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.2),
                                    ),
                                    boxShadow: isDark
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
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
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.slate900,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isCompact ? 12.h : 16.h),
                              ],
                              if (quest.plotStructure != null) ...[
                                Container(
                                  key: const Key('story_builder_narrative_arc'),
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.black.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.auto_stories_rounded,
                                            color: theme.primaryColor,
                                            size: 16.r,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            "STORY FLOW",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: theme.primaryColor,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        quest.plotStructure!
                                            .split(RegExp(r',\s*'))
                                            .join(' ➔ '),
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.slate900,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (quest.sequenceLogic != null) ...[
                                        SizedBox(height: 8.h),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                          ),
                                          child: Text(
                                            _formatSequenceLogic(
                                              quest.sequenceLogic!,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w600,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(height: isCompact ? 12.h : 16.h),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver:
                        (isFirstStagePassedNotifier.value ||
                            isAnsweredNotifier.value)
                        ? SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                key: ValueKey(
                                  '${quest.id}_${_retryCount}_${currentOrder[index]}',
                                ),
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: StoryBuilderNarrativeTile(
                                  key: Key('story_builder_tile_$index'),
                                  index: index,
                                  sentence:
                                      quest.sentences![currentOrder[index]],
                                  quest: quest,
                                  isHintVisible: state.isHintVisible,
                                  isDark: isDark,
                                  theme: theme,
                                  isAnswered: isAnsweredNotifier.value,
                                  isCorrect: isCorrectNotifier.value,
                                  isReorderable: false,
                                  originalIndex: currentOrder[index],
                                  isSelected: selectedIndex == index,
                                  onTap: () => _onTileTap(index),
                                ),
                              ),
                              childCount: currentOrder.length,
                            ),
                          )
                        : SliverReorderableList(
                            itemBuilder: (context, index) => Padding(
                              key: ValueKey(
                                '${quest.id}_${_retryCount}_${currentOrder[index]}',
                              ),
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: StoryBuilderNarrativeTile(
                                key: Key('story_builder_tile_$index'),
                                index: index,
                                sentence: quest.sentences![currentOrder[index]],
                                quest: quest,
                                isHintVisible: state.isHintVisible,
                                isDark: isDark,
                                theme: theme,
                                isAnswered: false,
                                isCorrect: null,
                                isReorderable: true,
                                originalIndex: currentOrder[index],
                                isSelected: selectedIndex == index,
                                onTap: () => _onTileTap(index),
                              ),
                            ),
                            itemCount: currentOrder.length,
                            onReorder: _onReorder,
                            onReorderStart: (index) {
                              hapticService.selection();
                            },
                            onReorderEnd: (index) {},
                            proxyDecorator: (child, index, animation) =>
                                Material(
                                  color: Colors.transparent,
                                  child: child.animate().scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.02, 1.02),
                                    duration: 150.ms,
                                  ),
                                ),
                          ),
                  ),
                  SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact =
                            constraints.maxHeight < _kCompactHeightBreakpoint;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            children: [
                              SizedBox(height: isCompact ? 16.h : 30.h),
                              if (!isAnsweredNotifier.value &&
                                  !isFirstStagePassedNotifier.value)
                                Semantics(
                                      button: true,
                                      label: context.tr(
                                        'games.finalize_story_caps',
                                        fallback: 'CHECK STORY',
                                      ),
                                      excludeSemantics: true,
                                      child: ScaleButton(
                                        key: const Key(
                                          'story_builder_finalize_button',
                                        ),
                                        onTap: () => _submitOrder(quest),
                                        child: Container(
                                          width: double.infinity,
                                          constraints: const BoxConstraints(
                                            minHeight: 48,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: isCompact ? 12.h : 16.h,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                theme.primaryColor,
                                                theme.primaryColor.withValues(
                                                  alpha: 0.85,
                                                ),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              isCompact ? 14.r : 16.r,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: isCompact ? 8 : 12,
                                                offset: Offset(
                                                  0,
                                                  isCompact ? 3 : 6,
                                                ),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              context.tr(
                                                'games.finalize_story_caps',
                                                fallback: 'CHECK STORY',
                                              ),
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: isCompact
                                                    ? 15.sp
                                                    : 16.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: 400.ms)
                                    .slideY(begin: 0.2),

                              SizedBox(
                                height: isAnsweredNotifier.value ? 160.h : 60.h,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (isFirstStagePassedNotifier.value &&
                      !isAnsweredNotifier.value)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          children: [
                            SpeakToConfirmOverlay(
                              key: const Key('story_builder_speak_overlay'),
                              expectedText:
                                  (quest.sentences != null &&
                                      quest.sentences!.isNotEmpty &&
                                      quest.correctOrder != null)
                                  ? quest.correctOrder!
                                        .map((i) => quest.sentences![i])
                                        .join(' ')
                                  : "Read the story aloud",
                              displayText:
                                  (quest.sentences != null &&
                                      quest.sentences!.isNotEmpty &&
                                      quest.correctOrder != null)
                                  ? quest.correctOrder!
                                        .map((i) => quest.sentences![i])
                                        .join(' ')
                                  : "Read the story aloud",
                              title: 'READ THE STORY',
                              subtitle: 'Read your completed story aloud',
                              displayFontSize: 15.sp,
                              displayFontWeight: FontWeight.w500,
                              displayTextAlign: TextAlign.center,
                              primaryColor: theme.primaryColor,
                              isPositioned: false,
                              onConfirmed: () =>
                                  _submitVerbalEvaluation(true, quest),
                              onSkipped: () =>
                                  _submitVerbalEvaluation(false, quest),
                            ),
                            SizedBox(height: 60.h),
                          ],
                        ),
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
