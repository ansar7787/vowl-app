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
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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

          if (state.isLetterRevealed && _currentInput.isEmpty && state.currentQuest.word != null) {
            final word = state.currentQuest.word!;
            final revealCount = word.length > 4 ? 2 : 1;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _currentInput.isEmpty) {
                for (int i = 0; i < revealCount; i++) {
                  final targetChar = word[i];
                  final idx = _shuffledChars.indexOf(targetChar);
                  if (idx != -1) {
                    _onCharTap(targetChar, idx);
                  }
                }
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
          title: (quest?.instruction ?? "Spell the word.").toUpperCase(),
          subtitle: "",
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 580;

        return Column(
          children: [
            SpeedSpellingInputField(
              currentInput: _currentInput,
              isAnswered: _isAnswered,
              isCorrect: _isCorrect,
              attempts: _attempts,
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
              shuffledChars: _shuffledChars,
              isDark: isDark,
              onCharTap: (char, index) => _onCharTap(char, index),
            ),
            SizedBox(height: isCompact ? 16.h : 32.h),
            if (!_isAnswered)
              ScaleButton(
                onTap: () => _submit(quest.word!),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 14.h : 20.h),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: isCompact ? 10 : 20,
                        offset: Offset(0, isCompact ? 5 : 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "SUBMIT",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: isCompact ? 16.sp : 18.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: isCompact ? 1.5 : 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
