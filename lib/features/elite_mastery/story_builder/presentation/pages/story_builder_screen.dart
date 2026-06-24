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
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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

  List<String> _currentOrder = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  int _attempts = 0;
  VisualConfig? _visualConfig;
  String? _lastQuestId;
  int? _lastLives;

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
    if (sentences.isEmpty) return;

    List<String> shuffled = List.from(sentences);
    // Shuffle until it's NOT the correct order
    int safetyCounter = 0;
    do {
      shuffled.shuffle();
      safetyCounter++;
    } while (_isCorrectSequence(shuffled, sentences, correctOrder) &&
        safetyCounter < 10);

    setState(() {
      _currentOrder = shuffled;
    });
  }

  bool _isCorrectSequence(
    List<String> current,
    List<String> original,
    List<int>? correctIndices,
  ) {
    if (correctIndices == null || current.length != correctIndices.length) {
      return false;
    }
    for (int i = 0; i < current.length; i++) {
      final originalIndex = original.indexOf(current[i]);
      if (originalIndex != correctIndices[i]) return false;
    }
    return true;
  }

  void _submitOrder(List<int>? correctOrder, List<String> originalSentences) {
    if (correctOrder == null || _isAnswered) return;

    bool isCorrect = _isCorrectSequence(
      _currentOrder,
      originalSentences,
      correctOrder,
    );

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
      _attempts++;

      final isFinalFailure = _attempts >= 2;
      setState(() {
        _isCorrect = false;
        if (isFinalFailure) {
          _isAnswered = true;
        } else {
          // Strike 1: Just show red borders, don't show feedback card yet
          _isAnswered = false;
        }
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
            title: 'STORY MASTER!',
            enableDoubleUp: true,
          );
        } else if (state is EliteMasteryLoaded) {
          final quest = state.currentQuest;
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));

          if (_lastQuestId != quest.id || livesChanged) {
            _lastQuestId = quest.id;
            _isAnswered = false;
            _isCorrect = null;
            _attempts = 0;
            _visualConfig = quest.visualConfig;
            _shuffleSentences(quest.sentences ?? [], quest.correctOrder);
          }
          _lastLives = state.livesRemaining;
          if (state.isHintVisible) {
            _hapticService.selection();
          }
          if (state.lastAnswerCorrect == true) {
            setState(() {
              _isAnswered = true;
              _isCorrect = true;
            });
          } else if (state.lastAnswerCorrect == false) {
            setState(() {
              _isCorrect = false;
              // If it's a final failure (either 2 strikes or out of lives), lock screen
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              }
            });
          }
        } else if (state is EliteMasteryGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () =>
                context.read<EliteMasteryBloc>().add(RestoreEliteLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is EliteMasteryLoaded) ? state.currentQuest : null;

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
          title: quest?.instruction ?? "Story Architect: Read the sentences and arrange them in the correct order.",
          visualConfig: _visualConfig,
          onContinue: () {
            setState(() {
              _isAnswered = true;
              _isCorrect = null;
              _attempts = 0;
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
    if (state is EliteMasteryLoading) {
      return const GameShimmerLoading();
    }
    if (state is EliteMasteryError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 48.r),
            SizedBox(height: 16.h),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            ScaleButton(
              onTap: () => context.read<EliteMasteryBloc>().add(
                FetchEliteMasteryQuests(
                  gameType: widget.gameType,
                  level: widget.level,
                ),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  context.tr('common.retry').toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
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
        final isCompact = constraints.maxHeight < 580;

        return Column(
          children: [
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: _onReorder,
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
                    key: ValueKey("${quest.id}_${_currentOrder[i]}_$i"),
                    padding: EdgeInsets.only(bottom: isCompact ? 10.h : 14.h),
                    child: StoryBuilderNarrativeTile(
                      index: i,
                      sentence: _currentOrder[i],
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
              ScaleButton(
                onTap: () =>
                    _submitOrder(quest.correctOrder, quest.sentences ?? []),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 14.h : 20.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
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
                      "FINALIZE STORY",
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
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        );
      },
    );
  }
}
