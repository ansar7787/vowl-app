import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_game_body.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';

import '../controllers/flashcard_controller.dart';

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

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late final FlashcardController _controller;
  late ThemeResult _theme;

  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    _controller = FlashcardController(
      hapticService: di.sl<HapticService>(),
      soundService: di.sl<SoundService>(),
      onSubmitAnswer: (mastered) {
        context.read<VocabularyBloc>().add(SubmitAnswer(mastered));
      },
    );
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
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
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: _onBlocState,
      builder: (context, state) {
        // Loading / unknown transient state

        // Error state — surfaces the message instead of hiding it in shimmer
        if (state is VocabularyError) {
          return _ErrorScaffold(
            message: state.message,
            primaryColor: _theme.primaryColor,
            onRetry: () => context.read<VocabularyBloc>().add(
              FetchVocabularyQuests(
                gameType: widget.gameType,
                level: widget.level,
              ),
            ),
          );
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
              showConfetti: _controller.showConfetti,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(const NextQuestion()),
              useScrolling: false,
              onHint: _controller.requestHint,
              child: quest == null
                  ? const SizedBox()
                  : FlashcardGameBody(
                      quest: quest,
                      primaryColor: _theme.primaryColor,
                      isDark: isDark,
                      isFlipped: _controller.isFlipped,
                      isAnswered: _controller.isAnswered,
                      isRetrying: _controller.isRetrying,
                      isHintActive: _controller.isHintActive,
                      hideActions: false,
                      dragOffset: _controller.dragOffset,
                      dragAngle: _controller.dragAngle,
                      onHorizontalDragUpdate:
                          _controller.onHorizontalDragUpdate,
                      onHorizontalDragEnd: _controller.onHorizontalDragEnd,
                      onCardTap: _controller.flipCard,
                      onSubmitAnswer: _controller.submitAnswer,
                    ),
            );
          },
        );
      },
    );
  }

  // ── BLoC listener ─────────────────────────────────────────────────────────

  void _onBlocState(BuildContext context, VocabularyState state) {
    if (state is VocabularyLoaded) {
      final isNew = state.currentIndex != _lastProcessedIndex;
      final isRetry = !state.answerStatus.isAnswered && _controller.isAnswered;
      if (isNew || isRetry) {
        _lastQuest = state.currentQuestOrNull ?? _lastQuest;
        _lastProcessedIndex = state.currentIndex;
        _controller.reset(isRetry);
      }
    } else if (state is VocabularyGameComplete) {
      _controller.completeGame();
      if (!context.mounted) return;
      GameDialogHelper.showCompletion(
        context,
        xp: state.xpEarned,
        coins: state.coinsEarned,
        title: 'VOCAB MASTERY!',
        enableDoubleUp: true,
      );
    }
  }
}

// ─── Error scaffold ───────────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final Color primaryColor;
  final VoidCallback onRetry;

  const _ErrorScaffold({
    required this.message,
    required this.primaryColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: primaryColor,
                size: 64.r,
              ),
              SizedBox(height: 16.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 24.h),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  context
                      .tr('games.try_again', fallback: 'Try Again')
                      .toUpperCase(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
