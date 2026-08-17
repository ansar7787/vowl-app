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
  bool _showConfetti = false;

  List<int> _currentOrder = [];
  bool _isAnswered = false;
  bool? _isCorrect;
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

  void _onReorder(int oldIndex, int newIndex) {
    if (_isAnswered) return;
    setState(() {
      _isCorrect = null; // Clear feedback borders on move
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
    });
    _hapticService.selection();
  }

  void _shuffleSentences(List<String> sentences, List<int>? correctOrder) {
    // FIX: previously just `if (sentences.isEmpty) return;` — leaving
    // whatever tiles the *previous* quest had shuffled still on screen,
    // mismatched against the new quest's (empty) sentences and correctOrder.
    // Clearing instead makes this fail safely (an empty list) rather than
    // fail confusingly with stale content.
    if (sentences.isEmpty) {
      setState(() => _currentOrder = []);
      return;
    }

    List<int> shuffled = List.generate(sentences.length, (i) => i);
    // Shuffle until it's NOT the correct order
    int safetyCounter = 0;
    do {
      shuffled.shuffle();
      safetyCounter++;
    } while (_isCorrectSequence(shuffled, correctOrder) && safetyCounter < 10);

    setState(() {
      _currentOrder = shuffled;
    });
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
    if (correctOrder == null || _isAnswered) return;

    bool isCorrect = _isCorrectSequence(_currentOrder, correctOrder);

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();

      setState(() {
        _isCorrect = false;
        _isAnswered = true;
      });
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
          setState(() => _showConfetti = true);
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
            setState(() {
              _lastQuestId = quest.id;
              _isAnswered = false;
              _isCorrect = null;
              _visualConfig = quest.visualConfig;
            });
            _shuffleSentences(quest.sentences ?? [], quest.correctOrder);
          } else if (!state.answerStatus.isAnswered) {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
            });
            _shuffleSentences(quest.sentences ?? [], quest.correctOrder);
          }
          _lastLives = state.livesRemaining;
          if (state.isHintVisible) {
            _hapticService.selection();
          }
          if (state.answerStatus == AnswerStatus.correct) {
            setState(() {
              _isAnswered = true;
              _isCorrect = true;
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            setState(() {
              _isCorrect = false;
              // If it's a final failure (either 2 strikes or out of lives), lock screen
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              }
            });
          }
        }
      },
      builder: (context, state) {
        return EliteBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          state: state,
          isCorrect: _isCorrect,
          isFinalFailure: (state is EliteMasteryLoaded)
              ? (state.isFinalFailure || state.livesRemaining <= 0)
              : false,
          showConfetti: _showConfetti,
          title: _isAnswered
              ? ""
              : (state is EliteMasteryLoaded &&
                    state.currentQuest.instruction.isNotEmpty)
              ? state.currentQuest.instruction
              : context.tr(
                  'games.story_builder_instruction',
                  fallback: 'Assemble the fragments into a correct story.',
                ),
          titleIcon: Icons.format_list_numbered_rounded,
          visualConfig: _visualConfig,
          onContinue: () {
            setState(() {
              // FIX: this was `_isAnswered = true` — inverted relative to
              // every other game's onContinue (and to this game's own
              // listener logic). For the instant between tapping Continue
              // and the bloc actually emitting the next quest, the builder
              // still renders the *old* EliteMasteryLoaded with
              // `_isAnswered` now forced true: EliteBaseLayout's
              // AnimatedOpacity dims the list to 0.6 and the just-dismissed
              // EliteFeedbackCard re-renders for a frame before the
              // corrected state arrives and reverses it — a visible flicker
              // on every single question transition across all 200 levels.
              _isAnswered = false;
              _isCorrect = null;
              _currentOrder = [];
            });
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < _kCompactHeightBreakpoint;

        return Column(
          children: [
            // FIX: every Story Builder quest carries a real, hand-written
            // narrative hint (verified across all four sample batches), and
            // tapping the hint button does spend it (MarkEliteHintUsed,
            // ShowEliteHint) — but this screen never actually rendered an
            // EliteHintCard anywhere, unlike all three sibling screens. The
            // only visible effect of "using a hint" was the small position
            // badge on each tile below; the actual clue text was completely
            // inaccessible, so every hint spent here bought strictly less
            // value than in any other game in the category.
            if (state.isHintVisible) ...[
              EliteHintCard(
                hintText: quest.hint,
                isVisible: true,
                onShowHint: () {},
                primaryColor: theme.primaryColor,
              ),
              SizedBox(height: isCompact ? 12.h : 20.h),
            ],
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: _onReorder,
              // FIX: `ReorderableListView` defaults `buildDefaultDragHandles`
              // to true, which auto-attaches its own platform drag handle
              // per item (visibly, on Android) in addition to this tile's
              // own custom `Icons.drag_indicator_rounded` — risking two
              // visible drag handles per row. Disabling the default and
              // wrapping the existing icon in a `ReorderableDragStartListener`
              // (inside StoryBuilderNarrativeTile) keeps exactly one handle,
              // consistently, on every platform.
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: child.animate().scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.02, 1.02),
                  duration: 150.ms,
                ),
              ),
              children: [
                for (int i = 0; i < _currentOrder.length; i++)
                  Padding(
                    // Keying on the original index is perfectly stable and
                    // prevents duplicate-key crashes if sentences are identical.
                    key: ValueKey('${quest.id}_${_currentOrder[i]}'),
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: StoryBuilderNarrativeTile(
                      index: i,
                      sentence: quest.sentences![_currentOrder[i]],
                      quest: quest,
                      isHintVisible: state.isHintVisible,
                      isDark: isDark,
                      theme: theme,
                      isAnswered: _isAnswered,
                      isCorrect: _isCorrect,
                    ),
                  ),
              ],
            ),
            SizedBox(height: isCompact ? 16.h : 30.h),
            if (!_isAnswered)
              Semantics(
                button: true,
                label: context.tr(
                  'games.finalize_story_caps',
                  fallback: 'FINALIZE STORY',
                ),
                excludeSemantics: true,
                child: ScaleButton(
                  onTap: () => _submitOrder(quest.correctOrder),
                  child: Container(
                    width: double.infinity,
                    // FIX: height was purely padding-driven, sitting right
                    // at the 48dp touch-target floor in compact mode and
                    // able to dip under it once ScreenUtil scales down on
                    // the smallest screens. This is the primary submit
                    // action for every question in this game.
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 14.h : 20.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        isCompact ? 16.r : 24.r,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.6),
                          blurRadius: isCompact ? 10 : 20,
                          offset: Offset(0, isCompact ? 5 : 10),
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
                          letterSpacing: isCompact ? 1.5 : 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        );
      },
    );
  }
}

