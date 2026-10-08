import '../../../domain/entities/elite_mastery_quest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';
import 'package:vowl/features/elite_mastery/presentation/mixins/elite_mastery_game_screen_mixin.dart';
import 'package:vowl/features/elite_mastery/presentation/layout/elite_base_layout.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_hint_card.dart';

import '../widgets/story_builder_narrative_tile.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class StoryBuilderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
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
  final ValueNotifier<bool> _isDraggingNotifier = ValueNotifier(false);
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
  }

  @override
  void dispose() {
    _currentOrder.dispose();
    _selectedTileIndex.dispose();
    _isDraggingNotifier.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 500.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      });
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
          
      final correctAnswer = (quest.sentences != null && quest.correctOrder != null)
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

  void _submitVerbalEvaluation(bool nailedIt, EliteMasteryQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      hapticService.success();
      soundService.playCorrect();
      context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(true));
    } else {
      final expectedText = (quest.sentences != null && quest.sentences!.isNotEmpty && quest.correctOrder != null)
          ? quest.correctOrder!.map((i) => quest.sentences![i]).join(' ')
          : "Narrate the story";
          
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
      _currentOrder.value =
          List.generate(state.currentQuest.sentences!.length, (i) => i);
    } else {
      _currentOrder.value = [];
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
    // `EliteMasteryLoading` and `EliteMasteryError` are both handled
    // centrally by `EliteBaseLayout`: it renders its own shimmer/error UI
    // directly inside its Stack and never includes this `child` slot for
    // either state, so no local UI is built (or ever shown) for them here.
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
        ListenableBuilder(
          listenable: Listenable.merge([
            _currentOrder,
            _selectedTileIndex,
            _isDraggingNotifier,
          ]),
          builder: (context, _) {
            final currentOrder = _currentOrder.value;
            final selectedIndex = _selectedTileIndex.value;
            final isDragging = _isDraggingNotifier.value;
            return RawScrollbar(
              controller: _scrollController,
              thumbColor: theme.primaryColor.withValues(alpha: 0.5),
              radius: Radius.circular(8.r),
              thickness: 4.w,
              child: CustomScrollView(
                physics: isDragging
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
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
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
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
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Text(
                                quest.instruction,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: isCompact ? 13.sp : 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 12.h : 20.h),
                          ],
                          if (quest.plotStructure != null) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.timeline_rounded,
                                        color: theme.primaryColor,
                                        size: 14.r,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        "NARRATIVE ARC",
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    quest.plotStructure!.split(RegExp(r',\s*')).join(' ➔ '),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (quest.sequenceLogic != null) ...[
                                    SizedBox(height: 6.h),
                                    Text(
                                      quest.sequenceLogic!.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor.withValues(alpha: 0.7),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: isCompact ? 12.h : 20.h),
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
                            index: index,
                            sentence:
                                quest.sentences![currentOrder[index]],
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
                          _isDraggingNotifier.value = true;
                          hapticService.selection();
                        },
                        onReorderEnd: (index) {
                          _isDraggingNotifier.value = false;
                        },
                        proxyDecorator: (child, index, animation) => Material(
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
                          if (!isAnsweredNotifier.value && !isFirstStagePassedNotifier.value)
                            Semantics(
                                  button: true,
                                  label: context.tr(
                                    'games.finalize_story_caps',
                                    fallback: 'FINALIZE STORY',
                                  ),
                                  excludeSemantics: true,
                                  child: ScaleButton(
                                    onTap: () =>
                                        _submitOrder(quest),
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
                                              alpha: 0.8,
                                            ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          isCompact ? 14.r : 18.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.4),
                                            blurRadius: isCompact ? 8 : 15,
                                            offset: Offset(
                                              0,
                                              isCompact ? 4 : 8,
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          context.tr(
                                            'games.finalize_story_caps',
                                            fallback: 'FINALIZE STORY',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: isCompact ? 15.sp : 16.sp,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: isCompact
                                                ? 1.5
                                                : 2.0,
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
              if (isFirstStagePassedNotifier.value && !isAnsweredNotifier.value)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SpeakToConfirmOverlay(
                        expectedText: (quest.sentences != null &&
                                quest.sentences!.isNotEmpty && quest.correctOrder != null)
                            ? quest.correctOrder!.map((i) => quest.sentences![i]).join(' ')
                            : "Narrate the story",
                        displayText: (quest.sentences != null &&
                                quest.sentences!.isNotEmpty && quest.correctOrder != null)
                            ? quest.correctOrder!.map((i) => quest.sentences![i]).join(' ')
                            : "Narrate the story",
                        title: 'NARRATE THE STORY',
                        subtitle: 'Read your completed story aloud',
                        displayFontSize: 15.sp,
                        displayFontWeight: FontWeight.w500,
                        displayTextAlign: TextAlign.left,
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
            ],
          ),
        );
       },
      ),
      ],
    );
  }
}
