import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/bloc/game_state_base.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

import 'package:vowl/core/presentation/models/game_scaffold_config.dart';
import 'package:vowl/core/presentation/widgets/game_scaffold.dart';

/// Levels on which the briefing overlay is shown automatically.
const Set<int> _kBriefingLevels = {1, 100};

/// Lives count that must remain for the TTS nudge to trigger.
const int _kLastLifeThreshold = 1;

/// Lives count the player must drop FROM to trigger the nudge.
const int _kNudgeTriggerLives = 2;

/// Delay before TTS nudge fires — lets sound effects settle first.
const Duration _kNudgeDelay = Duration(milliseconds: 1200);

typedef GameStateMapper<S> = GameStateBase Function(S state);
typedef HeaderBuilder<S> =
    Widget Function(BuildContext context, S state, double progress, int lives);
typedef FeedbackBuilder<S> = Widget Function(BuildContext context, S state);
typedef MascotBuilder<S> =
    Widget Function(BuildContext context, S state, int lives);
typedef ErrorRetryCallback = VoidCallback;

class GameBaseLayout<B extends StateStreamableSource<S>, S>
    extends StatefulWidget {
  final GameScaffoldConfig config;
  final GameStateMapper<S> stateMapper;

  // UI Builders
  final HeaderBuilder<S> headerBuilder;
  final FeedbackBuilder<S>? feedbackBuilder;
  final MascotBuilder<S>? mascotBuilder;
  final Widget? backgroundOverlay;
  final ErrorRetryCallback onRetry;
  final VoidCallback onRestoreLife;

  const GameBaseLayout({
    super.key,
    required this.config,
    required this.stateMapper,
    required this.headerBuilder,
    this.feedbackBuilder,
    this.mascotBuilder,
    this.backgroundOverlay,
    required this.onRetry,
    required this.onRestoreLife,
  });

  @override
  State<GameBaseLayout<B, S>> createState() => _GameBaseLayoutState<B, S>();
}

class _GameBaseLayoutState<B extends StateStreamableSource<S>, S>
    extends State<GameBaseLayout<B, S>> {
  late final TtsService _ttsService;
  late final SoundService _soundService;
  late final HapticService _hapticService;

  bool _hasSpokenNudge = false;
  int _lastLives = 3; // Start with 3 lives assumption
  bool _showBriefing = false;

  late final ValueNotifier<int> _stateHash = ValueNotifier(0);

  void _updateState() {
    if (mounted) _stateHash.value++;
  }

  @override
  void initState() {
    super.initState();
    _ttsService = di.sl<TtsService>();
    _soundService = di.sl<SoundService>();
    _hapticService = di.sl<HapticService>();
    _showBriefing = _kBriefingLevels.contains(widget.config.level);
  }

  @override
  void dispose() {
    _stateHash.dispose();
    _ttsService.stop();
    _soundService.stopAudio();
    super.dispose();
  }

  void _handleLastLifeNudge() {
    if (_hasSpokenNudge) return;
    _hasSpokenNudge = true;
    Future.delayed(_kNudgeDelay, () {
      if (!mounted) return;
      _ttsService.speak(context.tr('games.kids_nudge', fallback: 'Let\'s go!'));
      _hapticService.warning();
    });
  }

  void _onStateChange(BuildContext ctx, S state) {
    final baseState = widget.stateMapper(state);

    if (baseState is GameOverState) {
      GameDialogHelper.showGameOver(ctx, onRestore: widget.onRestoreLife);
      return;
    }

    if (baseState is! GameLoadedState) return;

    final justDroppedToLastLife =
        _lastLives == _kNudgeTriggerLives &&
        baseState.livesRemaining == _kLastLifeThreshold;

    if (justDroppedToLastLife) _handleLastLifeNudge();
    _lastLives = baseState.livesRemaining;
  }

  void _onExitPressed(BuildContext ctx) {
    GameDialogHelper.showExitConfirmation(
      ctx,
      onQuit: () => Navigator.of(ctx).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: (prev, curr) {
        final prevBase = widget.stateMapper(prev);
        final currBase = widget.stateMapper(curr);

        if (currBase is GameOverState && prevBase is! GameOverState) {
          return true;
        }
        if (currBase is! GameLoadedState) return false;
        if (prevBase is! GameLoadedState) return true;
        return prevBase.livesRemaining != currBase.livesRemaining ||
            prevBase.currentIndex != currBase.currentIndex;
      },
      listener: _onStateChange,
      child: BlocBuilder<B, S>(
        buildWhen: (prev, curr) {
          final prevBase = widget.stateMapper(prev);
          final currBase = widget.stateMapper(curr);

          if (prevBase.runtimeType != currBase.runtimeType) return true;
          if (currBase is GameLoadedState && prevBase is GameLoadedState) {
            return prevBase.currentIndex != currBase.currentIndex ||
                prevBase.lastAnswerCorrect != currBase.lastAnswerCorrect ||
                prevBase.hintUsed != currBase.hintUsed ||
                prevBase.isFinalFailure != currBase.isFinalFailure;
          }
          return true;
        },
        builder: (context, state) {
          final baseState = widget.stateMapper(state);
          final isComplete = baseState is GameCompleteState;

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
              child: ValueListenableBuilder<int>(
                valueListenable: _stateHash,
                builder: (context, _, child) {
                  return GameScaffold<S>(
                    state: state,
                    baseState: baseState,
                    config: widget.config,
                    headerBuilder: widget.headerBuilder,
                    feedbackBuilder: widget.feedbackBuilder,
                    mascotBuilder: widget.mascotBuilder,
                    backgroundOverlay: widget.backgroundOverlay,
                    showBriefing: _showBriefing,
                    onBriefingDismiss: () {
                      _showBriefing = false;
                      _updateState();
                    },
                    onBriefingShow: () {
                      _showBriefing = true;
                      _updateState();
                    },
                    onExitPressed: () => _onExitPressed(context),
                    onRetry: widget.onRetry,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
