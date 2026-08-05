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
import 'package:vowl/core/presentation/widgets/speak_to_confirm_overlay.dart';
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
  bool _isFirstStagePassed = false;
  List<int> _wrongIndices = []; 
  String? _lastQuestId;
  int _lastLives = 3;

  static const double _kCompactHeightBreakpoint = 580;

  @override
  void initState() {
    super.initState();
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _initializeOptions(GameQuest quest, {bool shouldSetState = true}) {
    if (quest.options == null || quest.options!.isEmpty) {
      void reset() {
        _shuffledOptions = [];
        _originalIndices = [];
        _selectedIndex = null;
        _wrongIndices = [];
        _isFirstStagePassed = false;
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
        _wrongIndices = []; 
        _isFirstStagePassed = false;
      });
    } else {
      _shuffledOptions = mapped.map((e) => e.value).toList();
      _originalIndices = mapped.map((e) => e.key).toList();
      _selectedIndex = null;
      _wrongIndices = []; 
      _isFirstStagePassed = false;
    }
  }

  void _onOptionSelected(int shuffledIndex, int? correctOriginalIndex) {
    if (_isAnswered || _isFirstStagePassed || _wrongIndices.contains(shuffledIndex)) return;

    final actualOriginalIndex = _originalIndices[shuffledIndex];
    final isCorrect = actualOriginalIndex == correctOriginalIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isFirstStagePassed = true;
        _selectedIndex = shuffledIndex;
      });
      // Do NOT submit yet! Wait for Phase 2.
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

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<EliteMasteryBloc>().add(const EliteSpeakConfirmed(5));
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
          final livesChanged = (state.livesRemaining > _lastLives);

          if (_lastQuestId != state.currentQuest.id || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastQuestId = state.currentQuest.id;
              _isAnswered = false;
              _isCorrect = null;
              _isFirstStagePassed = false;
            });
            _initializeOptions(state.currentQuest);
          } else if (state.lastAnswerCorrect == null) {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _isFirstStagePassed = false;
            });
          }
          if (state.lastAnswerCorrect == false) {
            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              }
            });
          }
          _lastLives = state.livesRemaining;
          
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
        
        final expectedText = quest != null && _selectedIndex != null 
            ? _shuffledOptions[_selectedIndex!]
            : "";

        return Stack(
          children: [
            EliteBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered,
              state: state,
              isCorrect: _isCorrect,
              isFinalFailure: (state is EliteMasteryLoaded)
                  ? (state.isFinalFailure || state.livesRemaining <= 0)
                  : false,
              showConfetti: _showConfetti,
              title: "",
              visualConfig: quest?.visualConfig,
              onContinue: () {
                setState(() {
                  _isAnswered = false;
                  _isCorrect = null;
                  _selectedIndex = null;
                  _wrongIndices = [];
                  _isFirstStagePassed = false;
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
            ),
            if (_isFirstStagePassed && !_isAnswered && quest != null)
              SpeakToConfirmOverlay(
                expectedText: expectedText,
                primaryColor: theme.primaryColor,
                onConfirmed: () => _submitVerbalEvaluation(true),
                onSkipped: () => _submitVerbalEvaluation(true), // Skip speaking but keep the correct answer
              ),
          ],
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.extension_rounded,
                        color: theme.primaryColor, size: 24.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        quest.instruction.isNotEmpty
                            ? quest.instruction
                            : context.tr(
                                'games.idiomMatch_instruction',
                                fallback: 'Select the matching idiom.',
                              ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 24.r + 12.w), // Balance the icon for true center
                  ],
                ),
              ),
            ),
            SizedBox(height: isCompact ? 16.h : 24.h),
            if (quest.question != null && quest.question!.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.02),
                            ]
                          : [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.7),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : theme.primaryColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: theme.primaryColor.withValues(alpha: 0.6),
                        size: 32.r,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        quest.question!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isCompact ? 16.sp : 18.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          height: 1.4,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
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
              isAnswered: _isAnswered || _isFirstStagePassed,
              showCorrectAnswer: _isCorrect == true || _isFirstStagePassed,
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
