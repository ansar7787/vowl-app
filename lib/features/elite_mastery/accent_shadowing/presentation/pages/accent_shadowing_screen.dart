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

  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<int> _attempts = ValueNotifier(0);
  final ValueNotifier<Set<int>> _matchedIndices = ValueNotifier({});
  String? _lastQuestId;

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
    _isAnswered.dispose();
    _isCorrect.dispose();
    _attempts.dispose();
    _matchedIndices.dispose();
        _scrollController.dispose();
    super.dispose();
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    if (nailedIt) {
      _matchedIndices.value = Set.from(
        Iterable.generate(100),
      ); // Highlight all on success
    }

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

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    _isAnswered.value = true;
    _isCorrect.value = true;
    _matchedIndices.value = Set.from(Iterable.generate(100)); // Highlight all
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
          _showConfetti.value = true;
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
          if (_lastQuestId != quest.id ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastQuestId = quest.id;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _attempts.value = 0;
            _matchedIndices.value = {};
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            if (state.isFinalFailure || state.livesRemaining <= 0) {
              _isAnswered.value = true;
            }
          }
        }
      },
      builder: (context, state) {
        final quest = (state is EliteMasteryLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _attempts, _matchedIndices]),
            builder: (context, _) {
              return EliteBaseLayout(
          onTutorPass: _tutorPass,
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered.value,
          state: state,
          isCorrect: _isCorrect.value,
          isFinalFailure:
              (state is EliteMasteryLoaded && state.isFinalFailure) ||
              (state is EliteMasteryLoaded ? state.livesRemaining <= 0 : false),
          showConfetti: _showConfetti.value,
          title: _isAnswered.value
              ? ""
              : quest?.instruction.isNotEmpty == true
              ? quest!.instruction
              : context.tr(
                  'games.accent_shadowing_instruction',
                  fallback:
                      'Listen to the example, then speak and match the exact accent and rhythm.',
                ),
          titleIcon: Icons.record_voice_over_rounded,
          useScrolling: false,
          onContinue: () {
            _isAnswered.value = false;
            _isCorrect.value = null;
            _attempts.value = 0;
            _matchedIndices.value = {};
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
                          final isCompact = constraints.maxHeight < _kCompactHeightBreakpoint;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: isCompact ? 5.h : 10.h,
                            ),
                            child: Column(
                              children: [
                                AccentShadowingTargetPanel(
                                  text:
                                      targetText ??
                                      context.tr(
                                        'games.target_text_fallback',
                                        fallback: 'Target Text',
                                      ),
                                  shadowingFocus: quest.shadowingFocus,
                                  targetAccent: quest.targetAccent,
                                  matchedIndices: _matchedIndices.value,
                                  isDark: isDark,
                                  primaryColor: theme.primaryColor,
                                  isAnswered: _isAnswered.value,
                                  isCorrect: _isCorrect.value,
                                  attempts: _attempts.value,
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

                                if (!_isAnswered.value)
                                  AccentSelfEvaluationPanel(
                                    textToSpeak:
                                        "", // Removed duplicate text, it's already shown in the target panel
                                    primaryColor: theme.primaryColor,
                                    isCompact: isCompact,
                                    onEvaluate: _submitVerbalEvaluation,
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
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60.h,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
