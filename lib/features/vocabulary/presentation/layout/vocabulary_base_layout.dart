import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/models/vocabulary_scaffold_config.dart';
import 'package:vowl/features/vocabulary/presentation/themes/vocab_level_theme.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_scaffold.dart';
import 'package:vowl/core/utils/locale_service.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

/// Levels on which the briefing overlay is shown automatically.
const Set<int> _kBriefingLevels = {1, 100};

/// Lives count that must remain for the TTS nudge to trigger.
const int _kLastLifeThreshold = 1;

/// Lives count the player must drop FROM to trigger the nudge.
const int _kNudgeTriggerLives = 2;

/// Delay before TTS nudge fires — lets sound effects settle first.
const Duration _kNudgeDelay = Duration(milliseconds: 1200);

// ─── Widget ───────────────────────────────────────────────────────────────────

class VocabularyBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final bool isFinalFailure;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final bool useScrolling;
  final bool disablePadding;

  const VocabularyBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.isCorrect,
    this.isFinalFailure = false,
    required this.onContinue,
    required this.onHint,
    this.showConfetti = false,
    this.useScrolling = false,
    this.disablePadding = false,
  });

  @override
  State<VocabularyBaseLayout> createState() => _VocabularyBaseLayoutState();
}

class _VocabularyBaseLayoutState extends State<VocabularyBaseLayout> {
  late final TtsService _ttsService;
  late final HapticService _hapticService;

  bool _hasSpokenNudge = false;
  int _lastLives = VocabularyRewardConstants.initialLives;
  bool _showBriefing = false;

  @override
  void initState() {
    super.initState();
    _ttsService = di.sl<TtsService>();
    _hapticService = di.sl<HapticService>();
    _showBriefing = _kBriefingLevels.contains(widget.level);
  }

  // ── Nudge ─────────────────────────────────────────────────────────────────

  void _handleLastLifeNudge() {
    if (_hasSpokenNudge) return;
    _hasSpokenNudge = true;
    Future.delayed(_kNudgeDelay, () {
      if (!mounted) return;
      _ttsService.speak(context.tr('games.kids_nudge', fallback: 'Let\'s go!'));
      _hapticService.warning();
    });
  }

  // ── State change listener ─────────────────────────────────────────────────

  void _onStateChange(BuildContext ctx, VocabularyState state) {
    // FIX: VocabularyGameOver now triggers GameDialogHelper — previously the
    // scaffold had no game-over UI, leaving the player on a frozen screen.
    if (state is VocabularyGameOver) {
      GameDialogHelper.showGameOver(
        ctx,
        onRestore: () => ctx.read<VocabularyBloc>().add(const RestoreLife()),
      );
      return;
    }

    if (state is! VocabularyLoaded) return;
    final justDroppedToLastLife =
        _lastLives == _kNudgeTriggerLives &&
        state.livesRemaining == _kLastLifeThreshold;
    if (justDroppedToLastLife) _handleLastLifeNudge();
    _lastLives = state.livesRemaining;
  }

  void _onExitPressed(BuildContext ctx) {
    GameDialogHelper.showExitConfirmation(
      ctx,
      onQuit: () => Navigator.of(ctx).pop(),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final VocabLevelTheme theme = VocabLevelTheme.from(
      LevelThemeHelper.getTheme(widget.gameType.name, isDark: isDark),
    );

    final config = VocabularyScaffoldConfig(
      gameType: widget.gameType,
      level: widget.level,
      child: widget.child,
      isAnswered: widget.isAnswered,
      isCorrect: widget.isCorrect,
      isFinalFailure: widget.isFinalFailure,
      onContinue: widget.onContinue,
      onHint: widget.onHint,
      showConfetti: widget.showConfetti,
      useScrolling: widget.useScrolling,
      disablePadding: widget.disablePadding,
    );

    return BlocListener<VocabularyBloc, VocabularyState>(
      listenWhen: (prev, curr) {
        // FIX: also fires when entering VocabularyGameOver so the dialog shows.
        if (curr is VocabularyGameOver && prev is! VocabularyGameOver) {
          return true;
        }
        if (curr is! VocabularyLoaded) return false;
        if (prev is! VocabularyLoaded) return true;
        return prev.livesRemaining != curr.livesRemaining ||
            prev.currentIndex != curr.currentIndex;
      },
      listener: _onStateChange,
      child: BlocBuilder<VocabularyBloc, VocabularyState>(
        buildWhen: (prev, curr) {
          if (prev.runtimeType != curr.runtimeType) return true;
          if (curr is VocabularyLoaded && prev is VocabularyLoaded) {
            return prev.currentIndex != curr.currentIndex ||
                prev.lastAnswerCorrect != curr.lastAnswerCorrect ||
                prev.hintUsed != curr.hintUsed ||
                prev.isFinalFailure != curr.isFinalFailure;
          }
          return true;
        },
        builder: (context, state) {
          final isComplete = state is VocabularyGameComplete;
          return PopScope(
            canPop: isComplete,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _onExitPressed(context);
            },
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(
                  context,
                ).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.1),
              ),
              child: VocabularyScaffold(
                state: state,
                theme: theme,
                isDark: isDark,
                config: config,
                showBriefing: _showBriefing,
                onBriefingDismiss: () => setState(() => _showBriefing = false),
                onBriefingShow: () => setState(() => _showBriefing = true),
                onExitPressed: () => _onExitPressed(context),
              ),
            ),
          );
        },
      ),
    );
  }
}
