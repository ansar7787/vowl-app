import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/layout/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import '../widgets/accent_shadowing_target_panel.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_self_evaluation_panel.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/elite_mastery/presentation/mixins/elite_mastery_game_screen_mixin.dart';

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

class _AccentShadowingScreenState extends State<AccentShadowingScreen>
    with EliteMasteryGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _attempts = ValueNotifier(0);
  final ValueNotifier<Set<int>> _matchedIndices = ValueNotifier({});

  static const double _kCompactHeightBreakpoint = 580;

  @override
  void initState() {
    super.initState();
    initEliteMasteryGame();
  }

  @override
  void dispose() {
    _attempts.dispose();
    _matchedIndices.dispose();
    _scrollController.dispose();
    disposeEliteMasteryGame();
    super.dispose();
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;
    if (nailedIt) {
      _matchedIndices.value = Set.from(
        Iterable.generate(100),
      ); // Highlight all on success
    }

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<EliteMasteryBloc>().add(const EliteSpeakConfirmed(5));
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _attempts.value = 0;

    _matchedIndices.value = {};
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
      listenWhen: eliteMasteryListenWhen,
      listener: onEliteMasteryStateChanged,
      builder: (context, state) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _attempts,
            _matchedIndices,
          ]),
          builder: (context, _) {
            return EliteBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              state: state,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure:
                  (state is EliteMasteryLoaded && state.isFinalFailure) ||
                  (state is EliteMasteryLoaded
                      ? state.livesRemaining <= 0
                      : false),
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              onContinue: () {
                isAnsweredNotifier.value = false;
                isCorrectNotifier.value = null;
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
                hasScrollBody: true,
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
                                  isAnswered: isAnsweredNotifier.value,
                                  isCorrect: isCorrectNotifier.value,
                                  attempts: _attempts.value,
                                  onListenTap: () =>
                                      soundService.playTts(targetText ?? ""),
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

                                if (!isAnsweredNotifier.value)
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
              SliverToBoxAdapter(child: SizedBox(height: 60.h)),
            ],
          ),
        ),
      ],
    );
  }
}
