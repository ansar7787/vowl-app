import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import '../controllers/flashcard_controller.dart';
import '../widgets/flashcard_speed_slam_view.dart';

/// 2026 Objective Mastery Phase screen for Vocabulary Flashcards.
///
/// Features the Speed Collocation Slam & Precision Strike arcade challenge.
/// 100% objective testing with 3 lives, a 5-second isolated speed fuse, and combo flame multipliers.
class FlashcardsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const FlashcardsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.flashcards,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with
        GameScreenMixin<FlashcardsScreen>,
        VocabularyGameScreenMixin<FlashcardsScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) =>
      context.tr('games.level_complete_caps', fallback: 'LEVEL COMPLETE!');

  late final FlashcardMasteryController _controller;
  late ThemeResult _theme;
  VocabularyQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    final initialBlocState = context.read<VocabularyBloc>().state;
    if (initialBlocState is VocabularyLoaded) {
      lastProcessedIndex = initialBlocState.currentIndex;
      _lastQuest = initialBlocState.currentQuestOrNull;
    }

    _controller = FlashcardMasteryController(
      hapticService: di.sl<HapticService>(),
      onSubmitResult: ({required bool isCorrect, required bool speedBonus}) {
        if (isCorrect) {
          submitCorrectAnswer();
        } else {
          final state = context.read<VocabularyBloc>().state;
          final q =
              (state is VocabularyLoaded ? state.currentQuestOrNull : null) ??
              _lastQuest;
          if (q != null) {
            submitWrongAnswer(quest: q, userAnswer: null);
          }
        }
      },
    );

    initVocabularyGame();
  }

  @override
  void onQuestionReset() {
    _controller.reset(isRetry: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _theme = LevelThemeHelper.getTheme(widget.gameType.name, isDark: isDark);
  }

  @override
  void dispose() {
    _controller.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: _onBlocState,
      builder: (context, state) {
        if (state is VocabularyError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(),
            ),
            body: GameErrorView(
              message: state.message,
              primaryColor: _theme.primaryColor,
              onRetry: () => context.read<VocabularyBloc>().add(
                FetchVocabularyQuests(
                  gameType: widget.gameType,
                  level: widget.level,
                ),
              ),
              onExit: () => Navigator.of(context).maybePop(),
            ),
          );
        }

        if (state is VocabularyLoaded) {
          _lastQuest = state.currentQuestOrNull ?? _lastQuest;
        }

        final VocabularyQuest? quest = state is VocabularyLoaded
            ? state.currentQuestOrNull
            : _lastQuest;

        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _controller.isAnswered,
              isCorrect: _controller.isCorrect,
              isFinalFailure: state is VocabularyLoaded
                  ? state.isFinalFailure
                  : false,
              showConfetti: _controller.showConfetti,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(const NextQuestion()),
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(
                      primaryColor: Theme.of(context).primaryColor,
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: FlashcardSpeedSlamView(
                          key: ValueKey(quest.id),
                          quest: quest,
                          controller: _controller,
                          isDark: isDark,
                          onAdvanceToStage2: () {
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  void _onBlocState(BuildContext context, VocabularyState state) {
    if (state is VocabularyLoaded) {
      final isNew = state.currentIndex != lastProcessedIndex;
      final isRetry =
          !isNew && !state.answerStatus.isAnswered && _controller.isAnswered;

      onVocabularyStateChanged(context, state);

      if (isNew || isRetry) {
        _lastQuest = state.currentQuestOrNull ?? _lastQuest;
        _controller.reset(isRetry: isRetry);
      }
    } else if (state is VocabularyGameComplete) {
      onVocabularyStateChanged(context, state);
      _controller.triggerVictoryCelebration();
    }
  }
}
