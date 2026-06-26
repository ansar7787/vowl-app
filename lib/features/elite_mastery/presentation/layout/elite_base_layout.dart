import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/painters/visual_config_background.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_feedback_card.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_game_header.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_peeking_mascot.dart';

import '../bloc/elite_mastery_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';

class EliteBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final String title;
  final String? subtitle;
  final bool isFinalFailure;
  final VisualConfig? visualConfig;
  final EliteMasteryState state;

  const EliteBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    required this.state,
    this.isCorrect,
    this.isFinalFailure = false,
    required this.onContinue,
    required this.onHint,
    this.showConfetti = false,
    required this.title,
    this.subtitle,
    this.visualConfig,
  });

  @override
  State<EliteBaseLayout> createState() => _EliteBaseLayoutState();
}

class _EliteBaseLayoutState extends State<EliteBaseLayout> {
  // ── Cached service references ────────────────────────────────────────────
  late final TtsService _ttsService = di.sl<TtsService>();
  late final HapticService _hapticService = di.sl<HapticService>();

  // ── Per-level state ──────────────────────────────────────────────────────
  bool _hasSpokenNudge = false;
  int _lastLives = _kMaxLives;
  int _lastIndex = -1;
  late bool _showBriefing;

  // ── Theme cache ──────────────────────────────────────────────────────────
  // FIX: previously typed `dynamic` under the assumption that `ThemeResult`
  // wasn't yet exported from `level_theme_helper.dart`. It is — sibling
  // screens (e.g. AccentShadowingScreen) already import it and type their
  // local theme variable as `ThemeResult` directly. Using the real type here
  // restores compile-time checking on every `.primaryColor` /
  // `.backgroundColors` access instead of deferring typos to runtime.
  ThemeResult? _cachedTheme;
  String? _cachedGameTypeName;
  int? _cachedLevel;
  bool? _cachedIsDark;
  bool? _cachedIsMidnight;

  // ── Constants ────────────────────────────────────────────────────────────
  static const int _kMaxLives = 3;
  static const Duration _kNudgeDelay = Duration(milliseconds: 1200);
  String get _kNudgeMessage => context.tr('games.kids_nudge');

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _showBriefing = widget.level == 1 || widget.level == 100;
  }

  @override
  void didUpdateWidget(EliteBaseLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _hasSpokenNudge = false;
      _lastLives = _kMaxLives;
      _lastIndex = -1;
      _cachedTheme = null; // invalidate when level changes
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  // ── Theme helper ─────────────────────────────────────────────────────────

  /// Returns a cached theme object, recomputing only when its inputs change.
  ///
  /// Without caching, [LevelThemeHelper.getTheme] was called on every BLoC
  /// state change — including answer submissions that don't change the theme.
  ThemeResult _getTheme(bool isDark, bool isMidnight) {
    if (_cachedTheme != null &&
        _cachedGameTypeName == widget.gameType.name &&
        _cachedLevel == widget.level &&
        _cachedIsDark == isDark &&
        _cachedIsMidnight == isMidnight) {
      return _cachedTheme!;
    }
    _cachedGameTypeName = widget.gameType.name;
    _cachedLevel = widget.level;
    _cachedIsDark = isDark;
    _cachedIsMidnight = isMidnight;
    _cachedTheme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      level: widget.level,
      isDark: isDark,
      isMidnight: isMidnight,
    );
    return _cachedTheme!;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // FIX: `context.watch<ThemeCubit>()` is called here for its side-effect:
    // subscribing this widget to ThemeCubit so it rebuilds when the theme
    // changes.  The actual theme object is computed in `_buildScaffold` where
    // it is consumed, avoiding the "local variable is set but never used" lint.
    context.watch<ThemeCubit>();

    final isComplete = widget.state is EliteMasteryGameComplete;

    return BlocListener<EliteMasteryBloc, EliteMasteryState>(
      listenWhen: (previous, current) {
        if (current is! EliteMasteryLoaded) return false;
        if (previous is! EliteMasteryLoaded) return true;
        return previous.currentIndex != current.currentIndex ||
            previous.livesRemaining != current.livesRemaining;
      },
      listener: _onBlocStateChange,
      child: PopScope(
        canPop: isComplete,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          GameDialogHelper.showExitConfirmation(
            context,
            onQuit: () => Navigator.of(context).pop(),
          );
        },
        child: BlocBuilder<EliteMasteryBloc, EliteMasteryState>(
          // Skip full rebuilds when only `isHintVisible` changes.
          // Nothing in EliteBaseLayout's own tree depends on hint visibility —
          // the hint card lives in `widget.child`, owned by the parent screen.
          buildWhen: (previous, current) {
            if (previous is EliteMasteryLoaded &&
                current is EliteMasteryLoaded) {
              return previous.quests != current.quests ||
                  previous.currentIndex != current.currentIndex ||
                  previous.livesRemaining != current.livesRemaining ||
                  previous.lastAnswerCorrect != current.lastAnswerCorrect ||
                  previous.isHintUsed != current.isHintUsed ||
                  previous.wrongCount != current.wrongCount ||
                  previous.isFinalFailure != current.isFinalFailure;
            }
            return previous.runtimeType != current.runtimeType;
          },
          builder: _buildScaffold,
        ),
      ),
    );
  }

  // ── BLoC listener ────────────────────────────────────────────────────────

  void _onBlocStateChange(BuildContext context, EliteMasteryState state) {
    if (state is! EliteMasteryLoaded) return;
    if (state.currentIndex != _lastIndex) _lastIndex = state.currentIndex;

    if (_lastLives == 2 && state.livesRemaining == 1 && !_hasSpokenNudge) {
      _hasSpokenNudge = true;
      Future.delayed(_kNudgeDelay, () {
        if (!mounted) return;
        _ttsService.stop();
        _ttsService.speak(_kNudgeMessage);
        _hapticService.warning();
      });
    }
    _lastLives = state.livesRemaining;
  }

  // ── Scaffold builder ─────────────────────────────────────────────────────

  Widget _buildScaffold(BuildContext context, EliteMasteryState state) {
    // `context.read` (not `watch`) — subscription is handled in `build()`.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.read<ThemeCubit>().state.isMidnight;
    final theme = _getTheme(isDark, isMidnight);

    if (state is EliteMasteryError) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.backgroundColors[1],
        body: GameErrorWidget(
          message: state.message,
          onRetry: () => context.read<EliteMasteryBloc>().add(
            FetchEliteMasteryQuests(
              gameType: widget.gameType,
              level: widget.level,
            ),
          ),
          onBack: () => Navigator.pop(context),
          primaryColor: theme.primaryColor,
        ),
      );
    }

    final progress = switch (state) {
      EliteMasteryLoaded s => (s.currentIndex + 1) / s.quests.length,
      EliteMasteryGameComplete _ => 1.0,
      _ => 0.0,
    };
    final lives = state is EliteMasteryLoaded
        ? state.livesRemaining
        : _kMaxLives;
    final quest = state is EliteMasteryLoaded ? state.currentQuest : null;

    return Scaffold(
      backgroundColor: theme.backgroundColors[1],
      body: Stack(
        children: [
          // Positioned.fill ensures this base layer actually covers the Stack.
          // A bare Container(color:) without explicit size is zero-sized in a Stack.
          Positioned.fill(child: ColoredBox(color: theme.backgroundColors[1])),
          RepaintBoundary(
            child: MeshGradientBackground(colors: theme.backgroundColors),
          ),
          if (widget.visualConfig != null)
            VisualConfigBackground(config: widget.visualConfig!)
          else if (quest?.visualConfig != null)
            VisualConfigBackground(config: quest!.visualConfig!),

          if (state is EliteMasteryLoading)
            GameShimmerLoading(primaryColor: theme.primaryColor)
          else
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  EliteGameHeader(
                    level: widget.level,
                    progress: progress,
                    lives: lives,
                    streak: state is EliteMasteryLoaded
                        ? state.currentIndex
                        : 0,
                    isAnswered: widget.isAnswered,
                    isHintUsed: state is EliteMasteryLoaded
                        ? state.isHintUsed
                        : false,
                    hintText: quest?.hint,
                    theme: theme,
                    isDark: isDark,
                    onBack: () => GameDialogHelper.showExitConfirmation(
                      context,
                      onQuit: () => Navigator.pop(context),
                    ),
                    onHint: widget.onHint,
                    onBriefing: () => setState(() => _showBriefing = true),
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
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.only(
                                left: 24.w,
                                right: 24.w,
                                top: 20.h,
                                bottom:
                                    (widget.isAnswered ? 200.h : 40.h) +
                                    MediaQuery.viewInsetsOf(context).bottom,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight:
                                        MediaQuery.sizeOf(context).height * 0.5,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          widget.title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize:
                                                (widget.subtitle == null ||
                                                    widget.subtitle!.isEmpty)
                                                ? 14.sp
                                                : 10.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing:
                                                (widget.subtitle == null ||
                                                    widget.subtitle!.isEmpty)
                                                ? 0
                                                : 4,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(
                                                    0xFF1E293B,
                                                  ).withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ).animate().fadeIn(),
                                      if (widget.subtitle != null &&
                                          widget.subtitle!.isNotEmpty) ...[
                                        SizedBox(height: 8.h),
                                        Semantics(
                                          liveRegion: true,
                                          child: Text(
                                            widget.subtitle!,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.w900,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ).animate().fadeIn().slideY(begin: 0.1),
                                      ],
                                      SizedBox(height: 32.h),
                                      widget.child,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -10.h,
                          left: 20.w,
                          child: ElitePeekingMascot(
                            state: state,
                            lives: lives,
                            isAnswered: widget.isAnswered,
                            isCorrect: widget.isCorrect,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (widget.isAnswered && state is EliteMasteryLoaded)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: EliteFeedbackCard(
                state: state,
                isCorrect: widget.isCorrect,
                onContinue: widget.onContinue,
                isDark: isDark,
              ),
            ),

          if (widget.showConfetti) const GameConfetti(),

          if (_showBriefing) _buildBriefing(theme),
        ],
      ),
    );
  }

  // ── Briefing overlay ─────────────────────────────────────────────────────

  Widget _buildBriefing(ThemeResult theme) {
    final briefing = GameInstructionService.getBriefing(
      context,
      widget.gameType,
      widget.title,
      level: widget.level,
    );
    return QuestBriefingOverlay(
      title: briefing.title,
      objective: briefing.objective,
      rules: briefing.rules,
      actionText: briefing.actionText,
      tip: briefing.tip,
      icon: briefing.icon,
      primaryColor: theme.primaryColor,
      onStart: () => setState(() => _showBriefing = false),
    );
  }
}
