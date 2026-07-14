import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_audio_player.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_base_layout_config.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_feedback_card.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_header.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_peeking_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

// =============================================================================
// ListeningBaseLayout
// =============================================================================

/// Shared scaffold used by every listening-game variant.
///
/// ## Backward-compatibility
/// All parameters that existed before the refactor still compile unchanged:
/// - [showConfetti], [useScrolling], [disablePadding] are direct `bool` params.
/// - [mascotId] is **optional**: if omitted the mascot ID is resolved from
///   [AuthBloc] at build time (same as the original behaviour). Pass it
///   explicitly in new call-sites to remove the cross-feature coupling.
///
/// New call-sites may alternatively pass a [ListeningBaseLayoutConfig] object
/// via [config] instead of the three boolean flags; if both are provided
/// [config] takes precedence.
class ListeningBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;

  /// The game-specific question UI (multiple-choice grid, fill-the-blank, …).
  final Widget child;

  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;

  // ── Backward-compatible direct flags ───────────────────────────────────────

  /// Fires the confetti overlay (level-complete celebration).
  final bool showConfetti;

  /// Wraps [child] in a [SingleChildScrollView].
  final bool useScrolling;

  /// Disables the default horizontal/vertical padding around [child].
  final bool disablePadding;

  // ── Optional extras ────────────────────────────────────────────────────────

  /// Resolved mascot ID (e.g. `'vowl_prime'`).
  ///
  /// - **Provide this** in new call-sites to avoid [AuthBloc] coupling.
  /// - **Omit it** in existing call-sites — the widget falls back to reading
  ///   `AuthBloc.state.user?.vowlMascot` at build time for full backward
  ///   compatibility.
  final String? mascotId;

  /// Audio URL (http) or plain text (spoken via TTS).
  final String? audioUrl;

  final bool isFinalFailure;

  /// Alternative to the three boolean flags above. If provided, its values
  /// override [showConfetti], [useScrolling], and [disablePadding].
  final ListeningBaseLayoutConfig? config;

  const ListeningBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    required this.onContinue,
    required this.onHint,
    // All of the following are optional so no existing call-site breaks.
    this.mascotId,
    this.isCorrect,
    this.audioUrl,
    this.isFinalFailure = false,
    this.showConfetti = false,
    this.useScrolling = false,
    this.disablePadding = false,
    this.config,
  });

  /// Resolves the effective config: explicit [config] wins; otherwise the
  /// three boolean params are used.
  ListeningBaseLayoutConfig get _effectiveConfig =>
      config ??
      ListeningBaseLayoutConfig(
        showConfetti: showConfetti,
        useScrolling: useScrolling,
        disablePadding: disablePadding,
      );

  @override
  State<ListeningBaseLayout> createState() => _ListeningBaseLayoutState();
}

// =============================================================================
// State
// =============================================================================

class _ListeningBaseLayoutState extends State<ListeningBaseLayout>
    with SingleTickerProviderStateMixin {
  final _ttsService = di.sl<TtsService>();
  final _soundService = di.sl<SoundService>();

  bool _hasSpokenNudge = false;
  int _lastLives = 3;
  int _lastIndex = -1;

  late AnimationController _audioController;
  late bool _showBriefing;
  Timer? _nudgeTimer;

  static const Duration _kNudgeDelay = Duration(milliseconds: 1200);
  String get _kNudgeMessage => context.tr('games.kids_nudge', fallback: 'Let\'s go!');

  @override
  void initState() {
    super.initState();
    _audioController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _showBriefing =
        widget._effectiveConfig.overrideBriefing ??
        (widget.level == 1 || widget.level == 100);
  }

  @override
  void didUpdateWidget(covariant ListeningBaseLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      setState(() {
        _showBriefing =
            widget._effectiveConfig.overrideBriefing ??
            (widget.level == 1 || widget.level == 100);
      });
    }
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _audioController.dispose();
    super.dispose();
  }

  void _handleAudioPlay() {
    final url = widget.audioUrl;
    if (url == null) return;
    if (url.startsWith('http')) {
      _soundService.playUrl(url);
    } else {
      _ttsService.speak(url);
    }
    _audioController.forward(from: 0);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      isDark: isDark,
    );

    // Resolve mascotId: prefer explicit param, fall back to AuthBloc for
    // existing call-sites that don't pass it.
    final resolvedMascotId =
        widget.mascotId ??
        context.read<AuthBloc>().state.user?.vowlMascot ??
        'vowl_prime';

    final effectiveConfig = widget._effectiveConfig;

    return BlocConsumer<ListeningBloc, ListeningState>(
      listenWhen: (prev, curr) {
        if (curr is! ListeningLoaded) return false;
        if (prev is! ListeningLoaded) return true;
        return prev.currentIndex != curr.currentIndex ||
            prev.livesRemaining != curr.livesRemaining;
      },
      listener: _onStateChange,
      builder: (context, state) {
        if (state is ListeningError) {
          return _ErrorScaffold(
            theme: theme,
            message: state.message,
            onRetry: () => context.read<ListeningBloc>().add(
              FetchListeningQuests(
                gameType: widget.gameType,
                level: widget.level,
              ),
            ),
          );
        }

        final isComplete = state is ListeningGameComplete;
        final progress = _resolveProgress(state, isComplete);
        final lives = state is ListeningLoaded ? state.livesRemaining : 3;
        final currentQuest = state is ListeningLoaded
            ? state.currentQuest
            : null;

        // Resolved once — not called 6× per frame.
        final briefing = _showBriefing
            ? GameInstructionService.getBriefing(
                context,
                widget.gameType,
                'Listening',
                level: widget.level,
              )
            : null;

        return PopScope(
          canPop: isComplete,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            GameDialogHelper.showExitConfirmation(
              context,
              onQuit: () => Navigator.of(context).pop(),
            );
          },
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(
                context,
              ).textScaler.clamp(maxScaleFactor: 1.3),
            ),
            child: Scaffold(
              backgroundColor: theme.backgroundColors[1],
              resizeToAvoidBottomInset: false,
              body: LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return Stack(
                    children: [
                      Container(color: theme.backgroundColors[1]),
                      MeshGradientBackground(colors: theme.backgroundColors),

                      if (state is ListeningLoading)
                        GameShimmerLoading(primaryColor: theme.primaryColor)
                      else
                        SafeArea(
                          child: isWide
                              ? _TabletLayout(
                                  widget: widget,
                                  state: state,
                                  theme: theme,
                                  isDark: isDark,
                                  lives: lives,
                                  progress: progress,
                                  currentQuest: currentQuest,
                                  soundService: _soundService,
                                  audioController: _audioController,
                                  effectiveConfig: effectiveConfig,
                                  resolvedMascotId: resolvedMascotId,
                                  onAudioPlay: _handleAudioPlay,
                                  onHint: _dispatchHint,
                                  onShowBriefing: _showBriefingOverlay,
                                  onBack: _confirmExit,
                                )
                              : _PhoneLayout(
                                  widget: widget,
                                  state: state,
                                  theme: theme,
                                  isDark: isDark,
                                  lives: lives,
                                  progress: progress,
                                  currentQuest: currentQuest,
                                  soundService: _soundService,
                                  audioController: _audioController,
                                  effectiveConfig: effectiveConfig,
                                  resolvedMascotId: resolvedMascotId,
                                  onAudioPlay: _handleAudioPlay,
                                  onHint: _dispatchHint,
                                  onShowBriefing: _showBriefingOverlay,
                                  onBack: _confirmExit,
                                ),
                        ),

                      // Feedback card — ListeningLoaded typed; no unsafe cast.
                      if (widget.isAnswered && state is ListeningLoaded)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: ListeningFeedbackCard(
                            state: state,
                            isCorrect: widget.isCorrect,
                            theme: theme,
                            isDark: isDark,
                            onContinue: widget.onContinue,
                          ),
                        ),

                      if (effectiveConfig.showConfetti) const GameConfetti(),

                      if (_showBriefing && briefing != null)
                        QuestBriefingOverlay(
                          title: briefing.title,
                          objective: briefing.objective,
                          rules: briefing.rules,
                          actionText: briefing.actionText,
                          tip: briefing.tip,
                          icon: briefing.icon,
                          primaryColor: theme.primaryColor,
                          onStart: _hideBriefing,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ── BlocConsumer listener ──────────────────────────────────────────────────

  void _onStateChange(BuildContext context, ListeningState state) {
    if (state is! ListeningLoaded) return;
    if (state.currentIndex != _lastIndex) _lastIndex = state.currentIndex;
    final droppedToLastLife = _lastLives == 2 && state.livesRemaining == 1;
    if (droppedToLastLife && !_hasSpokenNudge) {
      _hasSpokenNudge = true;
      _nudgeTimer?.cancel();
      _nudgeTimer = Timer(_kNudgeDelay, () {
        if (!mounted) return;
        _ttsService.stop();
        _ttsService.speak(_kNudgeMessage);
        di.sl<HapticService>().warning();
      });
    }
    _lastLives = state.livesRemaining;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double _resolveProgress(ListeningState state, bool isComplete) {
    if (state is ListeningLoaded) {
      return (state.currentIndex + 1) / state.quests.length;
    }
    return isComplete ? 1.0 : 0.0;
  }

  void _dispatchHint(BuildContext context) {
    context.read<ListeningBloc>().add(const ListeningHintUsed());
    widget.onHint();

    // ── OUTSTANDING VISUAL HINT (No JSON required) ──
    // Show a custom UI snackbar without clashing with the audio playback
    CustomSnackBar.show(
      context: context,
      message: "AUDIO CLUE ACTIVATED",
      type: CustomSnackBarType.info,
    );

    // Wait 1 second so the "hint.mp3" sound finishes playing
    // before we automatically replay the main game audio clip.
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _handleAudioPlay();
    });
  }

  void _showBriefingOverlay() => setState(() => _showBriefing = true);
  void _hideBriefing() => setState(() => _showBriefing = false);

  void _confirmExit(BuildContext context) {
    GameDialogHelper.showExitConfirmation(
      context,
      onQuit: () => Navigator.pop(context),
    );
  }
}

// =============================================================================
// _PhoneLayout  (single column)
// =============================================================================

class _PhoneLayout extends StatelessWidget {
  final ListeningBaseLayout widget;
  final ListeningState state;
  final dynamic theme;
  final bool isDark;
  final int lives;
  final double progress;
  final dynamic currentQuest;
  final SoundService soundService;
  final AnimationController audioController;
  final ListeningBaseLayoutConfig effectiveConfig;
  final String resolvedMascotId;
  final VoidCallback onAudioPlay;
  final void Function(BuildContext) onHint;
  final VoidCallback onShowBriefing;
  final void Function(BuildContext) onBack;

  const _PhoneLayout({
    required this.widget,
    required this.state,
    required this.theme,
    required this.isDark,
    required this.lives,
    required this.progress,
    required this.currentQuest,
    required this.soundService,
    required this.audioController,
    required this.effectiveConfig,
    required this.resolvedMascotId,
    required this.onAudioPlay,
    required this.onHint,
    required this.onShowBriefing,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10.h),
        ListeningHeader(
          level: widget.level,
          progress: progress,
          lives: lives,
          state: state,
          quest: currentQuest,
          theme: theme,
          isDark: isDark,
          isAnswered: widget.isAnswered,
          soundService: soundService,
          onHint: () => onHint(context),
          onShowBriefing: onShowBriefing,
          onBack: () => onBack(context),
        ),
        if (widget.audioUrl != null && !widget.isAnswered)
          ListeningAudioPlayer(
            theme: theme,
            isDark: isDark,
            audioUrl: widget.audioUrl!,
            audioController: audioController,
            onPlay: onAudioPlay,
          ),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: widget.isAnswered ? 0.6 : 1.0,
                child: AbsorbPointer(
                  absorbing: widget.isAnswered,
                  child: _ContentArea(
                    useScrolling: effectiveConfig.useScrolling,
                    disablePadding: effectiveConfig.disablePadding,
                    isAnswered: widget.isAnswered,
                    child: widget.child,
                  ),
                ),
              ),
              Positioned(
                top: -30.h,
                right: 20.w,
                child: RepaintBoundary(
                  child: ListeningPeekingMascot(
                    state: state,
                    lives: lives,
                    isCorrect: widget.isCorrect,
                    isAnswered: widget.isAnswered,
                    mascotId: resolvedMascotId,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _TabletLayout  (side-by-side ≥ 600 px)
// =============================================================================

class _TabletLayout extends StatelessWidget {
  final ListeningBaseLayout widget;
  final ListeningState state;
  final dynamic theme;
  final bool isDark;
  final int lives;
  final double progress;
  final dynamic currentQuest;
  final SoundService soundService;
  final AnimationController audioController;
  final ListeningBaseLayoutConfig effectiveConfig;
  final String resolvedMascotId;
  final VoidCallback onAudioPlay;
  final void Function(BuildContext) onHint;
  final VoidCallback onShowBriefing;
  final void Function(BuildContext) onBack;

  const _TabletLayout({
    required this.widget,
    required this.state,
    required this.theme,
    required this.isDark,
    required this.lives,
    required this.progress,
    required this.currentQuest,
    required this.soundService,
    required this.audioController,
    required this.effectiveConfig,
    required this.resolvedMascotId,
    required this.onAudioPlay,
    required this.onHint,
    required this.onShowBriefing,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10.h),
        ListeningHeader(
          level: widget.level,
          progress: progress,
          lives: lives,
          state: state,
          quest: currentQuest,
          theme: theme,
          isDark: isDark,
          isAnswered: widget.isAnswered,
          soundService: soundService,
          onHint: () => onHint(context),
          onShowBriefing: onShowBriefing,
          onBack: () => onBack(context),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left panel: mascot + audio player
              SizedBox(
                width: 260.w,
                child: Column(
                  children: [
                    if (widget.audioUrl != null && !widget.isAnswered)
                      ListeningAudioPlayer(
                        theme: theme,
                        isDark: isDark,
                        audioUrl: widget.audioUrl!,
                        audioController: audioController,
                        onPlay: onAudioPlay,
                      ),
                    Expanded(
                      child: Center(
                        child: RepaintBoundary(
                          child: ListeningPeekingMascot(
                            state: state,
                            lives: lives,
                            isCorrect: widget.isCorrect,
                            isAnswered: widget.isAnswered,
                            mascotId: resolvedMascotId,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Right panel: question content
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: widget.isAnswered ? 0.6 : 1.0,
                  child: AbsorbPointer(
                    absorbing: widget.isAnswered,
                    child: _ContentArea(
                      useScrolling: effectiveConfig.useScrolling,
                      disablePadding: effectiveConfig.disablePadding,
                      isAnswered: widget.isAnswered,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _ContentArea
// =============================================================================

class _ContentArea extends StatelessWidget {
  final bool useScrolling;
  final bool disablePadding;
  final bool isAnswered;
  final Widget child;

  const _ContentArea({
    required this.useScrolling,
    required this.disablePadding,
    required this.isAnswered,
    required this.child,
  });

  EdgeInsets _buildPadding(BuildContext context) {
    if (disablePadding) return EdgeInsets.zero;
    return EdgeInsets.only(
      left: 24.w,
      right: 24.w,
      top: 20.h,
      bottom:
          (isAnswered ? 200.h : 40.h) +
          MediaQuery.of(context).viewInsets.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = _buildPadding(context);
    if (useScrolling) {
      return LayoutBuilder(
        builder: (ctx, constraints) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }
    return Padding(padding: padding, child: child);
  }
}

// =============================================================================
// _ErrorScaffold
// =============================================================================

class _ErrorScaffold extends StatelessWidget {
  final dynamic theme;
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({
    required this.theme,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.backgroundColors[1],
      body: GameErrorWidget(
        message: message,
        onRetry: onRetry,
        onBack: () => Navigator.pop(context),
        primaryColor: theme.primaryColor,
      ),
    );
  }
}
