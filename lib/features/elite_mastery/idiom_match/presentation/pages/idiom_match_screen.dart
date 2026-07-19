import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/layout/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import '../widgets/idiom_match_options_panel.dart';

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

class _IdiomMatchScreenState extends State<IdiomMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  List<String> _shuffledOptions = [];
  List<int> _originalIndices = [];
  bool _showConfetti = false;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  List<int> _wrongIndices = []; // Stores indices relative to the SHUFFLED list
  String? _lastQuestId;
  int? _lastLives;

  // Below this available height, use tighter spacing so the question text,
  // hint card, and all 4 options comfortably fit without the player needing
  // to scroll on short viewports (landscape phones, split-screen, or with
  // the on-screen keyboard occupying vertical space).
  //
  // NOTE: this same breakpoint is duplicated across all 4 Elite Mastery game
  // screens (accent shadowing, idiom match, speed spelling, story builder).
  // Worth consolidating into one shared constant — see the review report's
  // Refactoring Opportunities section.
  static const double _kCompactHeightBreakpoint = 580;

  @override
  void initState() {
    super.initState();
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _initializeOptions(GameQuest quest, {bool shouldSetState = true}) {
    // FIX: previously just `if (quest.options == null) return;` — leaving
    // whatever the *previous* quest's shuffled options were still on
    // screen. Since `quest`/`quest.id` has already moved on by the time
    // this is called, that meant showing options that don't belong to the
    // current question at all, with taps resolving against the wrong
    // quest's correctAnswerIndex. Clearing instead of leaving stale state
    // makes this fail safely (an empty panel) rather than fail confusingly.
    if (quest.options == null || quest.options!.isEmpty) {
      void reset() {
        _shuffledOptions = [];
        _originalIndices = [];
        _selectedIndex = null;
        _wrongIndices = [];
      }

      if (shouldSetState) {
        setState(reset);
      } else {
        reset();
      }
      return;
    }

    final List<int> indices = List.generate(quest.options!.length, (i) => i);
    final List<MapEntry<int, String>> mapped = indices
        .map((i) => MapEntry(i, quest.options![i]))
        .toList();

    mapped.shuffle();

    if (shouldSetState) {
      setState(() {
        _shuffledOptions = mapped.map((e) => e.value).toList();
        _originalIndices = mapped.map((e) => e.key).toList();
        _selectedIndex = null;
        _wrongIndices = []; // Reset wrong indicators on shuffle
      });
    } else {
      _shuffledOptions = mapped.map((e) => e.value).toList();
      _originalIndices = mapped.map((e) => e.key).toList();
      _selectedIndex = null;
      _wrongIndices = []; // Reset wrong indicators on shuffle
    }
  }

  void _onOptionSelected(int shuffledIndex, int? correctOriginalIndex) {
    if (_isAnswered || _wrongIndices.contains(shuffledIndex)) return;

    final actualOriginalIndex = _originalIndices[shuffledIndex];
    final isCorrect = actualOriginalIndex == correctOriginalIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _selectedIndex = shuffledIndex;
      });
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();

      setState(() {
        if (!_wrongIndices.contains(shuffledIndex)) {
          _wrongIndices.add(shuffledIndex);
        }
        _isAnswered = true;
        _isCorrect = false;
        _selectedIndex = shuffledIndex;
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
              'games.idiom_legend_title',
              fallback: 'Idiom Legend',
            ),
            enableDoubleUp: true,
          );
        } else if (state is EliteMasteryLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));

          // FIX: these four lines used to mutate fields directly, outside
          // any setState, relying entirely on `_initializeOptions`'s own
          // internal setState (called immediately after) to flush the
          // rebuild. That happens to work today, but it's an implicit
          // dependency a future edit could silently break — e.g. if
          // `_initializeOptions` were ever called with `shouldSetState:
          // false` here. Wrapping explicitly removes that hazard.
          if (_lastQuestId != state.currentQuest.id || livesChanged) {
            setState(() {
              _lastQuestId = state.currentQuest.id;
              _isAnswered = false;
              _isCorrect = null;
            });
            _initializeOptions(state.currentQuest);
          } else if (state.lastAnswerCorrect == null) {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
            });
            _initializeOptions(state.currentQuest);
          }
          if (state.lastAnswerCorrect == false) {
            setState(() {
              _isCorrect = false;
              // If it's a final failure (either 2 strikes or out of lives), lock screen
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              }
            });
          }
          _lastLives = state.livesRemaining;
          // Dynamic Hint Logic (50/50 Lifeline) from Bloc
          if (state.removedIndices.isNotEmpty) {
            setState(() {
              for (final originalIdx in state.removedIndices) {
                final shuffledIdx = _originalIndices.indexOf(originalIdx);
                if (shuffledIdx != -1 && !_wrongIndices.contains(shuffledIdx)) {
                  _wrongIndices.add(shuffledIdx);
                }
              }
            });
          }
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
          title:
              quest?.instruction ??
              context.tr('games.idiom_master_title', fallback: 'Idiom Master'),
          visualConfig: quest?.visualConfig,
          onContinue: () {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _wrongIndices = [];
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
            if (quest.question != null && quest.question!.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  quest.question!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 16.sp : 18.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 16.h : 24.h),
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
            SizedBox(height: isCompact ? 16.h : 30.h),
            IdiomMatchOptionsPanel(
              shuffledOptions: _shuffledOptions,
              originalIndices: _originalIndices,
              selectedIndex: _selectedIndex,
              wrongIndices: _wrongIndices,
              isAnswered: _isAnswered,
              showCorrectAnswer: _isCorrect == true,
              correctAnswerIndex: quest.correctAnswerIndex ?? 0,
              isDark: isDark,
              primaryColor: theme.primaryColor,
              onOptionSelected: (index) =>
                  _onOptionSelected(index, quest.correctAnswerIndex),
            ),
            SizedBox(height: isCompact ? 12.h : 20.h),
          ],
        );
      },
    );
  }
}
