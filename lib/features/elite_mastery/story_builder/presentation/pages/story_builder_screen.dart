import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';
import 'package:vowl/features/elite_mastery/presentation/layout/elite_base_layout.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_hint_card.dart';
import '../widgets/story_builder_narrative_tile.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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

class _StoryBuilderScreenState extends State<StoryBuilderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<List<int>> _currentOrder = ValueNotifier([]);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  VisualConfig? _visualConfig;
  String? _lastQuestId;
  int _lastLives = 3;

  // Below this available height, use tighter spacing. See the identical
  // constant in accent_shadowing_screen.dart / idiom_match_screen.dart /
  // speed_spelling_screen.dart — worth consolidating into one shared
  // constant, noted in the review report's Refactoring Opportunities.
  static const double _kCompactHeightBreakpoint = 580;

  @override
  void initState() {
    super.initState();
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _showConfetti.dispose();
    _currentOrder.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _isFirstStagePassed.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_isAnswered.value) return;
    _isCorrect.value = null; // Clear feedback borders on move
    if (newIndex > oldIndex) newIndex -= 1;
    final newOrder = List<int>.from(_currentOrder.value);
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    _currentOrder.value = newOrder;
    _hapticService.selection();
  }

  void _shuffleSentences(List<String> sentences, List<int>? correctOrder) {
    // FIX: previously just `if (sentences.isEmpty) return;` — leaving
    // whatever tiles the *previous* quest had shuffled still on screen,
    // mismatched against the new quest's (empty) sentences and correctOrder.
    // Clearing instead makes this fail safely (an empty list) rather than
    // fail confusingly with stale content.
    if (sentences.isEmpty) {
      _currentOrder.value = [];
      return;
    }

    List<int> shuffled = List.generate(sentences.length, (i) => i);
    // Shuffle until it's NOT the correct order
    int safetyCounter = 0;
    do {
      shuffled.shuffle();
      safetyCounter++;
    } while (_isCorrectSequence(shuffled, correctOrder) && safetyCounter < 10);

    _currentOrder.value = shuffled;
  }

  bool _isCorrectSequence(List<int> current, List<int>? correctIndices) {
    if (correctIndices == null || current.length != correctIndices.length) {
      return false;
    }
    for (int i = 0; i < current.length; i++) {
      if (current[i] != correctIndices[i]) return false;
    }
    return true;
  }

  void _submitOrder(List<int>? correctOrder) {
    if (correctOrder == null || _isAnswered.value || _isFirstStagePassed.value) {
      return;
    }

    bool isCorrect = _isCorrectSequence(_currentOrder.value, correctOrder);

    if (isCorrect) {
      _hapticService.success();
      _isFirstStagePassed.value = true;
    } else {
      _hapticService.error();
      _soundService.playWrong();

      _isCorrect.value = false;
      _isAnswered.value = true;
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(false));
    }
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
      listener: (context, state) {
        if (state is EliteMasteryGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'games.story_master_title',
              fallback: 'Story Master',
            ),
            enableDoubleUp: true,
          );
        } else if (state is EliteMasteryLoaded) {
          final quest = state.currentQuest;
          final livesChanged = (state.livesRemaining > _lastLives);

          // FIX: these mutations used to happen directly on the fields,
          // outside any setState, relying entirely on `_shuffleSentences`'s
          // own internal setState (called right after) to flush the
          // rebuild. Wrapping explicitly removes that implicit dependency.
          if (_lastQuestId != quest.id || livesChanged) {
            _lastQuestId = quest.id;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;
            _visualConfig = quest.visualConfig;
            _shuffleSentences(quest.sentences ?? [], quest.correctOrder);
          } else if (!state.answerStatus.isAnswered) {
            _isAnswered.value = false;
            _isCorrect.value = null;
            _shuffleSentences(quest.sentences ?? [], quest.correctOrder);
          }
          _lastLives = state.livesRemaining;
          if (state.isHintVisible) {
            _hapticService.selection();
          }
          if (state.answerStatus == AnswerStatus.correct) {
            _isAnswered.value = true;
            _isCorrect.value = true;
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            if (state.isFinalFailure || state.livesRemaining <= 0) {
              _isAnswered.value = true;
            }
          }
        }
      },
      builder: (context, state) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _currentOrder,
            _isFirstStagePassed,
          ]),
          builder: (context, _) {
            return EliteBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              state: state,
              isCorrect: _isCorrect.value,
              isFinalFailure: (state is EliteMasteryLoaded)
                  ? (state.isFinalFailure || state.livesRemaining <= 0)
                  : false,
              showConfetti: _showConfetti.value,
              title: _isAnswered.value
                  ? ""
                  : (state is EliteMasteryLoaded &&
                        state.currentQuest.instruction.isNotEmpty)
                  ? state.currentQuest.instruction
                  : context.tr(
                      'games.story_builder_instruction',
                      fallback: 'Assemble the fragments into a correct story.',
                    ),
              titleIcon: Icons.format_list_numbered_rounded,
              useScrolling: false,
              disablePadding: true,
              visualConfig: _visualConfig,
              onContinue: () {
                _isAnswered.value = false;
                _isCorrect.value = null;
                _isFirstStagePassed.value = false;
                _currentOrder.value = [];
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
        RawScrollbar(
          controller: _scrollController,
          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
          radius: Radius.circular(8.r),
          thickness: 4.w,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
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
                          if (quest.plotStructure != null) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.2,
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
                                    quest.plotStructure!.split(',').join(' ➔ '),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
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
                sliver: _isFirstStagePassed.value && !_isAnswered.value
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            key: ValueKey(
                              '${quest.id}_${_currentOrder.value[index]}',
                            ),
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: StoryBuilderNarrativeTile(
                              index: index,
                              sentence:
                                  quest.sentences![_currentOrder.value[index]],
                              quest: quest,
                              isHintVisible: state.isHintVisible,
                              isDark: isDark,
                              theme: theme,
                              isAnswered: _isAnswered.value,
                              isCorrect: _isCorrect.value,
                            ),
                          ),
                          childCount: _currentOrder.value.length,
                        ),
                      )
                    : SliverReorderableList(
                        itemBuilder: (context, index) => Padding(
                          key: ValueKey(
                            '${quest.id}_${_currentOrder.value[index]}',
                          ),
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: StoryBuilderNarrativeTile(
                            index: index,
                            sentence:
                                quest.sentences![_currentOrder.value[index]],
                            quest: quest,
                            isHintVisible: state.isHintVisible,
                            isDark: isDark,
                            theme: theme,
                            isAnswered: _isAnswered.value,
                            isCorrect: _isCorrect.value,
                          ),
                        ),
                        itemCount: _currentOrder.value.length,
                        onReorder: _onReorder,
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
                          if (!_isAnswered.value)
                            Semantics(
                                  button: true,
                                  label: context.tr(
                                    'games.finalize_story_caps',
                                    fallback: 'FINALIZE STORY',
                                  ),
                                  excludeSemantics: true,
                                  child: ScaleButton(
                                    onTap: () =>
                                        _submitOrder(quest.correctOrder),
                                    child: Container(
                                      width: double.infinity,
                                      constraints: const BoxConstraints(
                                        minHeight: 48,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isCompact ? 14.h : 20.h,
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
                                          isCompact ? 16.r : 24.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.6),
                                            blurRadius: isCompact ? 10 : 20,
                                            offset: Offset(
                                              0,
                                              isCompact ? 5 : 10,
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
                                            fontSize: isCompact ? 16.sp : 18.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: isCompact
                                                ? 1.5
                                                : 2.5,
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
                            height:
                                _isAnswered.value || _isFirstStagePassed.value
                                ? 160.h
                                : 60.h,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_isFirstStagePassed.value && !_isAnswered.value)
          SpeakToConfirmOverlay(
            expectedText: quest.sentences != null && quest.sentences!.isNotEmpty
                ? quest.sentences![_currentOrder.value.last]
                : "Narrate the ending",
            displayText: "Narrate the final sentence to finish the story",
            primaryColor: theme.primaryColor,
            isPositioned: true,
            onConfirmed: () => _submitVerbalEvaluation(true),
            onSkipped: () => _submitVerbalEvaluation(false),
          ),
      ],
    );
  }
}
