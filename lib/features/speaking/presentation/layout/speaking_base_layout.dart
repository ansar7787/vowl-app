import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_feedback_card.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_game_header.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_peeking_mascot.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_voice_pulse_bg.dart';
import 'package:vowl/core/utils/locale_service.dart';

// ---------------------------------------------------------------------------
// Layout constants
// ---------------------------------------------------------------------------

const int _kNudgeDelayMs = 1200;
const int _kBriefingTriggerLevel = 1;
const int _kBriefingTutorialLevel = 100;

// =============================================================================
// SpeakingBaseLayout
// =============================================================================

class SpeakingBaseLayout extends StatefulWidget {
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

  /// Optional service overrides — inject mocks in widget tests to avoid
  /// requiring a live DI container. Production code leaves these null and
  /// the State falls back to [di.sl].
  final TtsService? ttsService;
  final SoundService? soundService;
  final HapticService? hapticService;

  const SpeakingBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    required this.onContinue,
    required this.onHint,
    this.isCorrect,
    this.isFinalFailure = false,
    this.showConfetti = false,
    this.useScrolling = false,
    this.disablePadding = false,
    this.ttsService,
    this.soundService,
    this.hapticService,
  });

  @override
  State<SpeakingBaseLayout> createState() => _SpeakingBaseLayoutState();
}

// =============================================================================
// State
// =============================================================================

class _SpeakingBaseLayoutState extends State<SpeakingBaseLayout> {
  // ---------------------------------------------------------------------------
  // Services — resolved once; override-friendly for tests
  // ---------------------------------------------------------------------------
  late final TtsService _ttsService;
  late final SoundService _soundService;
  late final HapticService _hapticService;

  // ---------------------------------------------------------------------------
  // Per-session trackers (reset in listener on SpeakingLoading)
  // ---------------------------------------------------------------------------
  bool _hasSpokenNudge = false;
  int _lastLives = 3;

  // ---------------------------------------------------------------------------
  // Mascot identity — cached in didChangeDependencies; stable per session
  // ---------------------------------------------------------------------------
  String _mascotId = 'vowl_prime';
  String _mascotName = 'Vowl Prime';

  late bool _showBriefing;
  Timer? _nudgeTimer;

  String get _kLastLifeNudge => context.tr('games.kids_nudge', fallback: 'Let\'s go!');

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? di.sl<TtsService>();
    _soundService = widget.soundService ?? di.sl<SoundService>();
    _hapticService = widget.hapticService ?? di.sl<HapticService>();
    _showBriefing = _shouldShowBriefing(widget.level);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache mascot identity — doesn't change during a game session.
    // didChangeDependencies is the correct hook for context-dependent reads.
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      _mascotId = user.vowlMascot ?? 'vowl_prime';
      _mascotName = _mascotId
          .split('_')
          .map((e) => e[0].toUpperCase() + e.substring(1))
          .join(' ');
    }
  }

  @override
  void didUpdateWidget(covariant SpeakingBaseLayout old) {
    super.didUpdateWidget(old);
    if (old.level != widget.level) {
      _showBriefing = _shouldShowBriefing(widget.level);
    }
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _shouldShowBriefing(int level) =>
      level == _kBriefingTriggerLevel || level == _kBriefingTutorialLevel;

  EdgeInsets _contentPadding({required bool isAnswered}) {
    if (widget.disablePadding) return EdgeInsets.zero;
    return EdgeInsets.only(
      left: 24.w,
      right: 24.w,
      top: 20.h,
      bottom: isAnswered ? 200.h : 40.h,
    );
  }

  void _showExitDialog(BuildContext context) {
    if (!mounted) return;
    GameDialogHelper.showExitConfirmation(
      context,
      onQuit: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  double _progress(SpeakingState s) {
    if (s is SpeakingLoaded) return (s.currentIndex + 1) / s.quests.length;
    return s is SpeakingGameComplete ? 1.0 : 0.0;
  }

  int _lives(SpeakingState s) => s is SpeakingLoaded ? s.livesRemaining : 3;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dynamic theme = LevelThemeHelper.getTheme(
      'speaking',
      level: widget.level,
    );

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      // ----- listenWhen: react to live-count changes and new fetches -----
      listenWhen: (prev, curr) {
        if (curr is SpeakingLoading) return true;
        if (curr is SpeakingLoaded) {
          if (prev is! SpeakingLoaded) return true;
          return prev.livesRemaining != curr.livesRemaining;
        }
        return false;
      },
      listener: (context, state) {
        if (state is SpeakingLoading) {
          // Reset per-session trackers so the nudge fires again on restart.
          _hasSpokenNudge = false;
          _lastLives = 3;
          _nudgeTimer?.cancel();
          return;
        }
        if (state is SpeakingLoaded) {
          final droppedToLastLife =
              _lastLives == 2 && state.livesRemaining == 1;
          if (droppedToLastLife && !_hasSpokenNudge) {
            _hasSpokenNudge = true;
            _nudgeTimer?.cancel();
            _nudgeTimer = Timer(
              const Duration(milliseconds: _kNudgeDelayMs),
              () {
                if (mounted) {
                  unawaited(_ttsService.speak(_kLastLifeNudge));
                  _hapticService.warning();
                }
              },
            );
          }
          _lastLives = state.livesRemaining;
        }
      },
      // ----- buildWhen: skip rebuilds when only wrongCount changed -----
      buildWhen: (prev, curr) {
        if (prev.runtimeType != curr.runtimeType) return true;
        if (prev is! SpeakingLoaded || curr is! SpeakingLoaded) {
          return prev != curr;
        }
        return prev.livesRemaining != curr.livesRemaining ||
            prev.currentIndex != curr.currentIndex ||
            prev.lastAnswerCorrect != curr.lastAnswerCorrect ||
            prev.hintUsed != curr.hintUsed ||
            prev.isFinalFailure != curr.isFinalFailure ||
            prev.quests.length != curr.quests.length;
      },
      builder: (context, state) {
        if (state is SpeakingError) {
          return _errorScaffold(context, state, theme);
        }

        final progress = _progress(state);
        final lives = _lives(state);
        final SpeakingQuest? quest = state is SpeakingLoaded
            ? state.currentQuest
            : null;
        final isComplete = state is SpeakingGameComplete;

        return PopScope(
          canPop: isComplete,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _showExitDialog(context);
          },
          child: Scaffold(
            backgroundColor: theme.backgroundColors[1],
            body: Stack(
              children: [
                // FIX: Positioned.fill ensures the ColoredBox fills the Stack.
                // A bare Container with color is 0x0 inside a Stack.
                Positioned.fill(
                  child: ColoredBox(color: theme.backgroundColors[1]),
                ),
                ExcludeSemantics(
                  child: MeshGradientBackground(colors: theme.backgroundColors),
                ),
                // FIX (performance): Gate pulse bg during loading to reclaim
                // GPU resources for the shimmer.
                if (state is! SpeakingLoading)
                  SpeakingVoicePulseBg(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                  ),

                if (state is SpeakingLoading)
                  GameShimmerLoading(primaryColor: theme.primaryColor)
                else
                  SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        SpeakingGameHeader(
                          level: widget.level,
                          progress: progress,
                          lives: lives,
                          streak: state is SpeakingLoaded
                              ? state.currentIndex
                              : 0,
                          quest: quest,
                          isAnswered: widget.isAnswered,
                          hintUsed: state is SpeakingLoaded && state.hintUsed,
                          soundService: _soundService,
                          isDark: isDark,
                          onBack: () => _showExitDialog(context),
                          onHintTap: widget.onHint,
                          onInfoTap: () => setState(() => _showBriefing = true),
                        ),
                        Expanded(child: _contentArea(context, state, lives)),
                      ],
                    ),
                  ),

                // Feedback card — type-safe: state is SpeakingLoaded narrows type.
                if (widget.isAnswered && state is SpeakingLoaded)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SpeakingFeedbackCard(
                      success: widget.isCorrect ?? false,
                      livesRemaining: state.livesRemaining,
                      isFinalFailure: state.isFinalFailure,
                      explanation: state.currentQuest.explanation,
                      onContinue: widget.onContinue,
                      isDark: isDark,
                    ),
                  ),

                if (widget.showConfetti) const GameConfetti(),
                if (_showBriefing) _briefingOverlay(context, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Content area
  // ---------------------------------------------------------------------------

  Widget _contentArea(BuildContext context, SpeakingState state, int lives) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final base = _contentPadding(isAnswered: widget.isAnswered);
    final effective = EdgeInsets.only(
      left: base.left,
      right: base.right,
      top: base.top,
      bottom: base.bottom + keyboard,
    );

    final Widget content = widget.useScrolling
        ? LayoutBuilder(
            builder: (_, constraints) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(padding: effective, child: widget.child),
              ),
            ),
          )
        : Padding(padding: effective, child: widget.child);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: widget.isAnswered ? 0.6 : 1.0,
          child: AbsorbPointer(absorbing: widget.isAnswered, child: content),
        ),
        Positioned(
          top: -20.h,
          right: 20.w,
          child: SpeakingPeekingMascot(
            state: state,
            lives: lives,
            isCorrect: widget.isCorrect,
            isAnswered: widget.isAnswered,
            mascotId: _mascotId,
            mascotName: _mascotName,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Error scaffold
  // ---------------------------------------------------------------------------

  Widget _errorScaffold(
    BuildContext context,
    SpeakingError error,
    dynamic theme,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.backgroundColors[1],
      body: GameErrorWidget(
        message: error.message,
        onRetry: () => context.read<SpeakingBloc>().add(
          FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
        ),
        onBack: () => Navigator.pop(context),
        primaryColor: theme.primaryColor,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Briefing overlay
  // ---------------------------------------------------------------------------

  Widget _briefingOverlay(BuildContext context, dynamic theme) {
    final b = GameInstructionService.getBriefing(
      context,
      widget.gameType,
      'Speaking',
      level: widget.level,
    );
    return QuestBriefingOverlay(
      title: b.title,
      objective: b.objective,
      rules: b.rules,
      actionText: b.actionText,
      tip: b.tip,
      icon: b.icon,
      primaryColor: theme.primaryColor,
      onStart: () => setState(() => _showBriefing = false),
    );
  }
}
