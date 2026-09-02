import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/layout/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import '../widgets/speed_spelling_input_field.dart';
import '../widgets/speed_spelling_character_deck.dart';

class SpeedSpellingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeedSpellingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speedSpelling,
  });

  @override
  State<SpeedSpellingScreen> createState() => _SpeedSpellingScreenState();
}

class _SpeedSpellingScreenState extends State<SpeedSpellingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _currentInput = ValueNotifier("");
  final ValueNotifier<List<String>> _shuffledChars = ValueNotifier([]);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<int> _attempts = ValueNotifier(0);
  final ValueNotifier<List<int>> _tapHistory = ValueNotifier([]);
  String? _lastQuestId;

  // Below this available height, use tighter spacing. See the identical
  // constant in accent_shadowing_screen.dart / idiom_match_screen.dart /
  // story_builder_screen.dart — worth consolidating into one shared
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
    _currentInput.dispose();
    _shuffledChars.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _attempts.dispose();
    _tapHistory.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCharTap(String char, int index) {
    if (_isAnswered.value || _shuffledChars.value[index] == "") return;

    _currentInput.value += char;

    final newChars = List<String>.from(_shuffledChars.value);
    newChars[index] = "";
    _shuffledChars.value = newChars;

    final newHistory = List<int>.from(_tapHistory.value);
    newHistory.add(index);
    _tapHistory.value = newHistory;

    _hapticService.light();
  }

  void _onBackspace() {
    if (_isAnswered.value || _tapHistory.value.isEmpty) return;

    final newHistory = List<int>.from(_tapHistory.value);
    final lastIndex = newHistory.removeLast();
    _tapHistory.value = newHistory;

    final newChars = List<String>.from(_shuffledChars.value);
    newChars[lastIndex] = _currentInput.value[_currentInput.value.length - 1];
    _shuffledChars.value = newChars;

    _currentInput.value = _currentInput.value.substring(
      0,
      _currentInput.value.length - 1,
    );

    _hapticService.selection();
  }

  void _onClear() {
    if (_isAnswered.value) return;
    final state = context.read<EliteMasteryBloc>().state;
    if (state is EliteMasteryLoaded) {
      _currentInput.value = "";
      _tapHistory.value = [];
      _shuffledChars.value = (state.currentQuest.word ?? '').split('')
        ..shuffle();
    }
    _hapticService.selection();
  }

  void _submit(String correctWord) {
    if (_isAnswered.value) return;
    if (_currentInput.value.length != correctWord.length) return;
    final isCorrect =
        _currentInput.value.toLowerCase() == correctWord.toLowerCase();

    _attempts.value++;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isAnswered.value = true;
      _isCorrect.value = true;
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();

      _isCorrect.value = false;
      _isAnswered.value = true;
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
              'games.spelling_legend_title',
              fallback: 'Spelling Legend',
            ),
            enableDoubleUp: true,
          );
        } else if (state is EliteMasteryLoaded) {
          final quest = state.currentQuest;
          if (_lastQuestId != quest.id) {
            _lastQuestId = quest.id;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _attempts.value = 0;
            _currentInput.value = "";
            _tapHistory.value = [];
            _shuffledChars.value = (quest.word ?? '').split('')..shuffle();
          } else if (!state.answerStatus.isAnswered) {
            _isAnswered.value = false;
            _isCorrect.value = null;
            _currentInput.value = "";
            _tapHistory.value = [];
            _shuffledChars.value = (quest.word ?? '').split('')..shuffle();
          }
          if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            if (state.isFinalFailure || state.livesRemaining <= 0) {
              _isAnswered.value = true;
            }
          }
          if (state.isHintVisible) {
            _hapticService.selection();
          }

          if (state.isLetterRevealed &&
              _currentInput.value.isEmpty &&
              state.currentQuest.word != null) {
            final word = state.currentQuest.word!;
            final revealCount = word.length > 4 ? 2 : 1;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _currentInput.value.isEmpty) {
                for (int i = 0; i < revealCount; i++) {
                  final targetChar = word[i];
                  final idx = _shuffledChars.value.indexOf(targetChar);
                  if (idx != -1) {
                    _onCharTap(targetChar, idx);
                  }
                }
              }
            });
          }
        }
      },
      builder: (context, state) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _currentInput,
            _shuffledChars,
            _attempts,
            _tapHistory,
          ]),
          builder: (context, _) {
            return EliteBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              state: state,
              isCorrect: _isCorrect.value,
              isFinalFailure:
                  state.livesRemaining <= 0 ||
                  (state is EliteMasteryLoaded && state.isFinalFailure),
              showConfetti: _showConfetti.value,
              useScrolling: false,
              onContinue: () {
                _isAnswered.value = false;
                _isCorrect.value = null;
                _currentInput.value = "";
                _tapHistory.value = [];
                _shuffledChars.value = [];
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
                        // FIX: Idiom Match's equivalent ad-dialog callback
                        // already dispatches MarkEliteHintUsed() here (needed
                        // for its 50/50 lifeline to activate); this screen's
                        // didn't. Currently inert either way, since this game's
                        // curriculum always supplies real hint text so this
                        // branch is never actually reached — but this game also
                        // has a fully-built letter-reveal mechanic in the Bloc
                        // that depends on exactly this call. Added for
                        // consistency and to not silently block that mechanic
                        // if it's ever wired up to be reachable. See the review
                        // report's Curriculum Utilization section.
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

    // Safety initialization if listener missed the first state
    if (_shuffledChars.value.isEmpty && quest.word != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shuffledChars.value.isEmpty) {
          _currentInput.value = "";
          _shuffledChars.value = quest.word!.split('')..shuffle();
        }
      });
    }

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
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact =
                              constraints.maxHeight < _kCompactHeightBreakpoint;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: isCompact ? 5.h : 10.h,
                            ),
                            child: Column(
                              children: [
                                if (quest.difficultyTier != null) ...[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: quest.difficultyTier == 'Rare'
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : (quest.difficultyTier ==
                                                      'Advanced'
                                                  ? Colors.orange.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.green.withValues(
                                                      alpha: 0.1,
                                                    )),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: quest.difficultyTier == 'Rare'
                                              ? Colors.redAccent.withValues(
                                                  alpha: 0.3,
                                                )
                                              : (quest.difficultyTier ==
                                                        'Advanced'
                                                    ? Colors.orangeAccent
                                                          .withValues(
                                                            alpha: 0.3,
                                                          )
                                                    : Colors.greenAccent
                                                          .withValues(
                                                            alpha: 0.3,
                                                          )),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            quest.difficultyTier == 'Rare'
                                                ? Icons
                                                      .local_fire_department_rounded
                                                : (quest.difficultyTier ==
                                                          'Advanced'
                                                      ? Icons.star_half_rounded
                                                      : Icons
                                                            .star_border_rounded),
                                            color:
                                                quest.difficultyTier == 'Rare'
                                                ? Colors.redAccent
                                                : (quest.difficultyTier ==
                                                          'Advanced'
                                                      ? Colors.orangeAccent
                                                      : Colors.greenAccent),
                                            size: 14.r,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            quest.difficultyTier!.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  quest.difficultyTier == 'Rare'
                                                  ? Colors.redAccent
                                                  : (quest.difficultyTier ==
                                                            'Advanced'
                                                        ? Colors.orangeAccent
                                                        : Colors.greenAccent),
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                ],
                                if (!_isAnswered.value)
                                  TweenAnimationBuilder<double>(
                                    key: ValueKey(quest.id),
                                    tween: Tween(begin: 30.0, end: 0.0),
                                    duration: const Duration(seconds: 30),
                                    builder: (context, value, child) {
                                      final color = value > 10
                                          ? theme.primaryColor
                                          : Colors.redAccent;
                                      return Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "SPEED BONUS",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                              Text(
                                                "${value.ceil()}s",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: color,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          LinearProgressIndicator(
                                            value: value / 30.0,
                                            backgroundColor: color.withValues(
                                              alpha: 0.1,
                                            ),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  color,
                                                ),
                                            minHeight: 4.h,
                                            borderRadius: BorderRadius.circular(
                                              2.r,
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                        ],
                                      );
                                    },
                                  ),
                                SpeedSpellingInputField(
                                  currentInput: _currentInput.value,
                                  isAnswered: _isAnswered.value,
                                  isCorrect: _isCorrect.value,
                                  attempts: _attempts.value,
                                  isDark: isDark,
                                  primaryColor: theme.primaryColor,
                                  onBackspace: _onBackspace,
                                  onClear: _onClear,
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
                                SpeedSpellingCharacterDeck(
                                  shuffledChars: _shuffledChars.value,
                                  isDark: isDark,
                                  onCharTap: (char, index) =>
                                      _onCharTap(char, index),
                                ),
                                SizedBox(height: isCompact ? 16.h : 32.h),
                                if (!_isAnswered.value) ...[
                                  Builder(
                                    builder: (context) {
                                      final canSubmit =
                                          _currentInput.value.length ==
                                          (quest.word?.length ?? 0);
                                      return Semantics(
                                        button: true,
                                        label: context.tr(
                                          'games.submit_caps',
                                          fallback: 'SUBMIT',
                                        ),
                                        excludeSemantics: true,
                                        child: Opacity(
                                          opacity: canSubmit ? 1.0 : 0.5,
                                          child: ScaleButton(
                                            // FIX: was `_submit(quest.word!)` — see _onClear for
                                            // rationale. An empty fallback just resolves to "wrong
                                            // answer" rather than crashing the screen outright.
                                            onTap: canSubmit
                                                ? () =>
                                                      _submit(quest.word ?? '')
                                                : null,
                                            child: Container(
                                              width: double.infinity,
                                              // FIX: height was purely padding-driven (14-20.h
                                              // vertical + text), which sits right at the 48dp
                                              // touch-target floor in compact mode and could dip
                                              // under it once ScreenUtil scales down on the smallest
                                              // screens. This is the primary submit action for every
                                              // question in this game — worth the extra insurance.
                                              constraints: const BoxConstraints(
                                                minHeight: 48,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: isCompact
                                                    ? 14.h
                                                    : 20.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isCompact ? 16.r : 24.r,
                                                    ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: isCompact
                                                        ? 10
                                                        : 20,
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
                                                    'games.submit_caps',
                                                    fallback: 'SUBMIT',
                                                  ),
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: isCompact
                                                        ? 16.sp
                                                        : 18.sp,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                    letterSpacing: isCompact
                                                        ? 1.5
                                                        : 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 60.h)),
            ],
          ),
        ),
      ],
    );
  }
}
