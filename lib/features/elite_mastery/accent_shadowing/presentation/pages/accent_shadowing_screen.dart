import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/layout/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import '../widgets/accent_shadowing_target_panel.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_self_evaluation_panel.dart';
import 'package:vowl/core/utils/locale_service.dart';

class AccentShadowingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AccentShadowingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.accentShadowing,
  });

  @override
  State<AccentShadowingScreen> createState() => _AccentShadowingScreenState();
}

class _AccentShadowingScreenState extends State<AccentShadowingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _showConfetti = false;
  bool _isAnswered = false;
  bool? _isCorrect;
  int _attempts = 0;
  Set<int> _matchedIndices = {};
  String? _lastQuestId;

  static const double _kCompactHeightBreakpoint = 580;

  @override
  void initState() {
    super.initState();
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;

    if (nailedIt) {
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _matchedIndices = Set.from(Iterable.generate(100)); // Highlight all on success
      });
      _hapticService.success();
      _soundService.playCorrect();
      context.read<EliteMasteryBloc>().add(const EliteSpeakConfirmed(5));
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      
      // Increment local attempts but keep panel open for immediate retry
      setState(() {
        _attempts++;
        _isCorrect = false;
      });
      
      // Send false to decrement life in Bloc
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(false));
    }
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _matchedIndices = Set.from(Iterable.generate(100)); // Highlight all
    });
    context.read<EliteMasteryBloc>().add(EliteTutorPass());
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
              'games.accent_legend_title',
              fallback: 'Accent Legend',
            ),
            enableDoubleUp: true,
          );
        } else if (state is EliteMasteryLoaded) {
          final quest = state.currentQuest;
          if (_lastQuestId != quest.id || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastQuestId = quest.id;
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _matchedIndices = {};
            });
          } else if (state.lastAnswerCorrect == false) {
            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              }
            });
          }
        }
      },
      builder: (context, state) {
        final quest = (state is EliteMasteryLoaded) ? state.currentQuest : null;

        return EliteBaseLayout(
          onTutorPass: _tutorPass,
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          state: state,
          isCorrect: _isCorrect,
          isFinalFailure:
              (state is EliteMasteryLoaded && state.isFinalFailure) ||
              (state is EliteMasteryLoaded ? state.livesRemaining <= 0 : false),
          showConfetti: _showConfetti,
          title:
              quest?.instruction ??
              context.tr(
                'games.accent_shadowing_instruction',
                fallback: 'Listen and repeat the sentence exactly as you hear it.',
              ),
          onContinue: () {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _matchedIndices = {};
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
    final targetText = quest.text ?? quest.textToSpeak;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < _kCompactHeightBreakpoint;

        return Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.record_voice_over_rounded, color: theme.primaryColor, size: 24.r),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "Phase 1: Listen to the example.\nPhase 2: Speak and match the exact accent and rhythm.",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AccentShadowingTargetPanel(
              text:
                  targetText ??
                  context.tr(
                    'games.target_text_fallback',
                    fallback: 'Target Text',
                  ),
              shadowingFocus: quest.shadowingFocus,
              matchedIndices: _matchedIndices,
              isDark: isDark,
              primaryColor: theme.primaryColor,
              isAnswered: _isAnswered,
              isCorrect: _isCorrect,
              attempts: _attempts,
              onListenTap: () => _soundService.playTts(targetText ?? ""),
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
            
            if (!_isAnswered)
              AccentSelfEvaluationPanel(
                textToSpeak: targetText ?? "",
                primaryColor: theme.primaryColor,
                isCompact: isCompact,
                onEvaluate: _submitVerbalEvaluation,
              ),
          ],
        );
      },
    );
  }
}
