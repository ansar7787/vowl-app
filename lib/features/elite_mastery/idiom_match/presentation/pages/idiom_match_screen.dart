import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/widgets/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

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
  int _attempts = 0;
  List<int> _wrongIndices = []; // Stores indices relative to the SHUFFLED list
  String? _lastQuestId;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _initializeOptions(GameQuest quest, {bool shouldSetState = true}) {
    if (quest.options == null) return;

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
    _attempts++;

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

      final isFinalFailure = _attempts >= 2;
      setState(() {
        if (!_wrongIndices.contains(shuffledIndex)) {
          _wrongIndices.add(shuffledIndex);
        }
        if (isFinalFailure) {
          _isAnswered = true;
          _isCorrect = false;
          _selectedIndex = shuffledIndex;
        } else {
          // Strike 1: Re-shuffle for next attempt
          _selectedIndex = null;
          // Re-shuffle options to close the loophole
          final state = context.read<EliteMasteryBloc>().state;
          if (state is EliteMasteryLoaded) {
            _initializeOptions(state.currentQuest, shouldSetState: false);
          }
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
            this.context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'IDIOM LEGEND!',
            enableDoubleUp: true,
          );
        } else if (state is EliteMasteryLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          
          if (_lastQuestId != state.currentQuest.id || livesChanged) {
            _lastQuestId = state.currentQuest.id;
            _isAnswered = false;
            _isCorrect = null;
            _attempts = 0;
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
          // Dynamic Hint Logic: If no specific hint text, reveal one wrong answer
          if (state.isHintVisible &&
              (state.currentQuest.hint == null ||
                  state.currentQuest.hint!.isEmpty)) {
            final quest = state.currentQuest;
            if (_wrongIndices.length < (quest.options?.length ?? 0) - 1) {
              final List<int> potentialWrongs = [];
              for (int i = 0; i < (quest.options?.length ?? 0); i++) {
                if (i != quest.correctAnswerIndex &&
                    !_wrongIndices.contains(i)) {
                  potentialWrongs.add(i);
                }
              }
              if (potentialWrongs.isNotEmpty) {
                final randomWrong = (potentialWrongs..shuffle()).first;
                setState(() {
                  if (!_wrongIndices.contains(randomWrong)) {
                    _wrongIndices.add(randomWrong);
                  }
                });
              }
            }
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
          isFinalFailure: (state is EliteMasteryLoaded) ? (state.isFinalFailure || state.livesRemaining <= 0) : false,
          showConfetti: _showConfetti,
          title: "IDIOM MASTER",
          subtitle: quest?.instruction ?? "Match the idiom to its real meaning",
          visualConfig: quest?.visualConfig,
          onContinue: () {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
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
              style: GoogleFonts.outfit(
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
                  "RETRY",
                  style: GoogleFonts.outfit(
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

    return Column(
      children: [
        GlassTile(
          borderRadius: BorderRadius.circular(32.r),
          padding: EdgeInsets.all(30.r),
          color: isDark
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.9),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome_rounded, 
                color: isDark ? Colors.white : theme.primaryColor, 
                size: 32.r,
              ),
              SizedBox(height: 16.h),
              Text(
                quest.idiom ?? "??",
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (state.isHintVisible) ...[
          SizedBox(height: 20.h),
          EliteHintCard(
            hintText: quest.hint,
            isVisible: true,
            onShowHint: () {},
            primaryColor: theme.primaryColor,
          ),
        ],
        SizedBox(height: 30.h),
        Column(
          children: List.generate(_shuffledOptions.length, (index) {
            final option = _shuffledOptions[index];
            final isSelected = _selectedIndex == index;
            final isWrong = _wrongIndices.contains(index);
            final isCorrect =
                _isAnswered &&
                _originalIndices[index] == quest.correctAnswerIndex;
            Color textColor = isDark ? Colors.white : Colors.black87;

            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: ScaleButton(
                onTap: _isAnswered
                    ? null
                    : () => _onOptionSelected(index, quest.correctAnswerIndex),
                child: GlassTile(
                  borderRadius: BorderRadius.circular(24.r),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 22.h,
                  ),
                  usePremiumStyle: true,
                  showShadow: true,
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : null,
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green
                        : (isWrong
                              ? Colors.red
                              : (isSelected
                                    ? Colors.green
                                    : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08)))),
                    width: 1.5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.outfit(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isWrong)
                        Icon(
                          Icons.cancel_rounded,
                          color: Colors.redAccent,
                          size: 24.r,
                        ).animate().shake(duration: 400.ms),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1),
            );
          }),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
