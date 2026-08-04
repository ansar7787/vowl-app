import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_audio_player.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_base_layout_config.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_header.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_peeking_mascot.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

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


  late AnimationController _audioController;
  Timer? _nudgeTimer;

  @override
  void initState() {
    super.initState();
    _audioController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void didUpdateWidget(covariant ListeningBaseLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
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

    final resolvedMascotId =
        widget.mascotId ??
        context.select<AuthBloc, String?>(
          (bloc) => bloc.state.user?.vowlMascot,
        ) ??
        'vowl_prime';

    final effectiveConfig = widget._effectiveConfig;

    return BlocBuilder<ListeningBloc, ListeningState>(
      builder: (context, state) {
        final currentQuest = state is ListeningLoaded ? state.currentQuest : null;

        final wrappedChild = LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return isWide
                ? _TabletLayoutContent(
                    widget: widget,
                    state: state,
                    theme: theme,
                    isDark: isDark,
                    lives: state.livesRemaining,
                    currentQuest: currentQuest,
                    soundService: _soundService,
                    audioController: _audioController,
                    effectiveConfig: effectiveConfig,
                    resolvedMascotId: resolvedMascotId,
                    onAudioPlay: _handleAudioPlay,
                  )
                : _PhoneLayoutContent(
                    widget: widget,
                    state: state,
                    theme: theme,
                    isDark: isDark,
                    lives: state.livesRemaining,
                    currentQuest: currentQuest,
                    soundService: _soundService,
                    audioController: _audioController,
                    effectiveConfig: effectiveConfig,
                    resolvedMascotId: resolvedMascotId,
                    onAudioPlay: _handleAudioPlay,
                  );
          },
        );

        final config = GameScaffoldConfig(
          gameType: widget.gameType,
          level: widget.level,
          child: wrappedChild,
          isAnswered: widget.isAnswered,
          isCorrect: widget.isCorrect,
          isFinalFailure: widget.isFinalFailure,
          onContinue: widget.onContinue,
          onHint: () => _dispatchHint(context),
          showConfetti: effectiveConfig.showConfetti,
          useScrolling: false, // Handled internally
          disablePadding: true, // Handled internally
        );

        return GameBaseLayout<ListeningBloc, ListeningState>(
          config: config,
          stateMapper: (s) => s,
          onRetry: () => context.read<ListeningBloc>().add(
            FetchListeningQuests(gameType: widget.gameType, level: widget.level),
          ),
          onRestoreLife: () => context.read<ListeningBloc>().add(const RestoreLife()),
          headerBuilder: (context, s, progress, lvs) {
            final currentQuest = s is ListeningLoaded ? s.currentQuest : null;
            return ListeningHeader(
              level: widget.level,
              progress: progress,
              lives: lvs,
              state: s,
              quest: currentQuest,
              theme: theme,
              isDark: isDark,
              isAnswered: widget.isAnswered,
              soundService: _soundService,
              onHint: () => _dispatchHint(context),
              onShowBriefing: () {}, // GameBaseLayout handles briefing
              onBack: () => GameDialogHelper.showExitConfirmation(
                context,
                onQuit: () => Navigator.of(context).pop(),
              ),
            );
          },
          feedbackBuilder: (context, s) {
            if (s is! ListeningLoaded) return const SizedBox.shrink();
            
            final quest = s.currentQuest;
            String? explanation = quest.explanation;
            final resolvedIsFinalFailure = s.isFinalFailure;
            if (explanation == null && widget.isCorrect == false && resolvedIsFinalFailure) {
               if (quest.correctAnswerIndex != null && quest.options != null && quest.options!.isNotEmpty) {
                   explanation = quest.options![quest.correctAnswerIndex!];
               }
            }
            
            final ruleContent = quest.audioTranscript ?? explanation;
            final finalExplanation = (ruleContent == explanation) ? null : explanation;
            
            return GameFeedbackCard(
              isCorrect: widget.isCorrect,
              isFinalFailure: resolvedIsFinalFailure,
              livesRemaining: s.livesRemaining,
              onContinue: widget.onContinue,
              isDark: isDark,
              primaryColor: theme.primaryColor,
              explanation: finalExplanation,
              ruleTitle: 'LISTENING TRANSCRIPT',
              ruleContent: ruleContent,
            );
          },
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
}

// =============================================================================
// =============================================================================
// _PhoneLayoutContent  (single column content)
// =============================================================================

class _PhoneLayoutContent extends StatelessWidget {
  final ListeningBaseLayout widget;
  final ListeningState state;
  final dynamic theme;
  final bool isDark;
  final int lives;
  final dynamic currentQuest;
  final SoundService soundService;
  final AnimationController audioController;
  final ListeningBaseLayoutConfig effectiveConfig;
  final String resolvedMascotId;
  final VoidCallback onAudioPlay;

  const _PhoneLayoutContent({
    required this.widget,
    required this.state,
    required this.theme,
    required this.isDark,
    required this.lives,
    required this.currentQuest,
    required this.soundService,
    required this.audioController,
    required this.effectiveConfig,
    required this.resolvedMascotId,
    required this.onAudioPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
// =============================================================================
// _TabletLayoutContent  (side-by-side content)
// =============================================================================

class _TabletLayoutContent extends StatelessWidget {
  final ListeningBaseLayout widget;
  final ListeningState state;
  final dynamic theme;
  final bool isDark;
  final int lives;
  final dynamic currentQuest;
  final SoundService soundService;
  final AnimationController audioController;
  final ListeningBaseLayoutConfig effectiveConfig;
  final String resolvedMascotId;
  final VoidCallback onAudioPlay;

  const _TabletLayoutContent({
    required this.widget,
    required this.state,
    required this.theme,
    required this.isDark,
    required this.lives,
    required this.currentQuest,
    required this.soundService,
    required this.audioController,
    required this.effectiveConfig,
    required this.resolvedMascotId,
    required this.onAudioPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

