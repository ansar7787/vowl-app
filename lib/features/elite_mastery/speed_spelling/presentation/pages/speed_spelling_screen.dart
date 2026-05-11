import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/widgets/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

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
  bool _showConfetti = false;
  String _currentInput = "";
  List<String> _shuffledChars = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  int _attempts = 0;
  List<int> _tapHistory = [];

  @override
  void initState() {
    super.initState();
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onCharTap(String char, int index) {
    if (_isAnswered || _shuffledChars[index] == "") return;
    setState(() {
      _currentInput += char;
      _shuffledChars[index] = "";
      _tapHistory.add(index);
    });
    _hapticService.light();
  }

  void _onBackspace() {
    if (_isAnswered || _tapHistory.isEmpty) return;
    setState(() {
      final lastIndex = _tapHistory.removeLast();
      _shuffledChars[lastIndex] = _currentInput[_currentInput.length - 1];
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    });
    _hapticService.selection();
  }

  void _onClear() {
    if (_isAnswered) return;
    final state = context.read<EliteMasteryBloc>().state;
    if (state is EliteMasteryLoaded) {
      setState(() {
        _currentInput = "";
        _tapHistory.clear();
        _shuffledChars = state.currentQuest.word!.split('')..shuffle();
      });
    }
    _hapticService.selection();
  }

  void _submit(String correctWord) {
    if (_isAnswered) return;
    final isCorrect = _currentInput.toLowerCase() == correctWord.toLowerCase();

    _attempts++;

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

      final isFinalFailure = _attempts >= 2;
      setState(() {
        _isCorrect = false;
        if (isFinalFailure) {
          _isAnswered = true;
        } else {
          // Strike 1: Allow retry without feedback card
          _isAnswered = false;
          _currentInput = "";
          final state = context.read<EliteMasteryBloc>().state;
          if (state is EliteMasteryLoaded) {
            _shuffledChars = state.currentQuest.word!.split('')..shuffle();
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
            title: 'SPELLING LEGEND!',
            enableDoubleUp: true,
          );
        } else if (state is EliteMasteryLoaded) {
          if (state.lastAnswerCorrect == null) {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _currentInput = "";
              _tapHistory = [];
              _shuffledChars = state.currentQuest.word!.split('')..shuffle();
            });
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
          if (state.isHintVisible) {
            _hapticService.selection();
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
          title: "LEXICAL BLITZ",
          subtitle: quest?.instruction ?? "Master the Spelling",
          onContinue: () {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _currentInput = "";
              _tapHistory = [];
              _shuffledChars = [];
            });
            context.read<EliteMasteryBloc>().add(NextEliteQuestion());
          },
          onHint: () {
            final bloc = context.read<EliteMasteryBloc>();
            final s = bloc.state;
            if (s is EliteMasteryLoaded) {
              if (s.currentQuest.hint != null && s.currentQuest.hint!.isNotEmpty) {
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
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 48.r,
            ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
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

    // Safety initialization if listener missed the first state
    if (_shuffledChars.isEmpty && quest.word != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shuffledChars.isEmpty) {
          setState(() {
            _currentInput = "";
            _shuffledChars = quest.word!.split('')..shuffle();
          });
        }
      });
    }

    return Column(
      children: [
        Container(
          height: 100.h,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _isCorrect == true
                ? LinearGradient(
                    colors: [
                      Colors.greenAccent.withValues(alpha: 0.2),
                      Colors.greenAccent.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: (_isAnswered || (_isCorrect == false && _attempts > 0))
                  ? (_isCorrect == true
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : Colors.redAccent.withValues(alpha: 0.6))
                  : (isDark ? Colors.white : Colors.black.withValues(alpha: 0.1)),
              width: 2.5,
            ),
            boxShadow: _isCorrect == true
                ? [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: -5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 90.w, // Safe space for Backspace + Clear buttons
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _currentInput,
                      style: GoogleFonts.outfit(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w900,
                        color: _isCorrect == true
                            ? Colors.greenAccent
                            : (isDark ? theme.primaryColor : const Color(0xFF0F172A)),
                        letterSpacing: 6,
                        shadows: _isCorrect == true
                            ? [
                                Shadow(
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 20,
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ),
                ),
              ),
              if (_currentInput.isNotEmpty && !_isAnswered)
                Positioned(
                  right: 12.w,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleButton(
                          onTap: _onBackspace,
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.backspace_rounded,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              size: 18.r,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ScaleButton(
                          onTap: _onClear,
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.refresh_rounded,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              size: 18.r,
                            ),
                          ),
                        ),
                      ],
                    ),
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
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children: List.generate(_shuffledChars.length, (index) {
            final char = _shuffledChars[index];
            return ScaleButton(
              onTap: char == "" ? null : () => _onCharTap(char, index),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: char == "" ? 0.3 : 1.0,
                child: Container(
                  width: 54.r,
                  height: 54.r,
                  decoration: BoxDecoration(
                    color: char == ""
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.black.withValues(alpha: 0.02))
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: char == ""
                          ? (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05))
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.08)),
                      width: 1.5,
                    ),
                    boxShadow: char == ""
                        ? []
                        : [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      char,
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 32.h),
        if (!_isAnswered)
          ScaleButton(
            onTap: () => _submit(quest.word!),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "SUBMIT",
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
