import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_feedback_card.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_peeking_mascot.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Shared scaffold for all Roleplay game variants.
///
/// Responsibilities:
///  - Renders header (progress, lives, hint button).
///  - Renders the scrollable content area.
///  - Orchestrates the peeking mascot, feedback card, confetti, and briefing.
///  - Fires the low-life voice nudge via [TtsService].
///
/// **No cross-feature coupling** — caller supplies [mascotId] so this widget
/// does not need to read [AuthBloc] directly.
class RoleplayBaseLayout extends StatefulWidget {
  const RoleplayBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.mascotId = kRoleplayDefaultMascotId,
    this.isCorrect,
    this.isFinalFailure = false,
    required this.onContinue,
    required this.onHint,
    this.showConfetti = false,
    this.title = 'SOCIAL SCENARIO',
    this.subtitle = 'Master the Scene',
    this.scrollController,
    this.useScrolling = false,
    this.disablePadding = false,
  });

  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final bool isFinalFailure;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final String title;
  final String subtitle;
  final ScrollController? scrollController;
  final bool useScrolling;
  final bool disablePadding;

  /// Mascot asset identifier sourced from the player's profile.
  /// Passed in by the screen — keeps this widget free of [AuthBloc] coupling.
  final String mascotId;

  @override
  State<RoleplayBaseLayout> createState() => _RoleplayBaseLayoutState();
}

class _RoleplayBaseLayoutState extends State<RoleplayBaseLayout> {
  final _ttsService = di.sl<TtsService>();
  final _soundService = di.sl<SoundService>();
  final _hapticService = di.sl<HapticService>();

  bool _hasSpokenNudge = false;
  int? _lastLives;
  late bool _showBriefing;
  Timer? _nudgeTimer;

  @override
  void initState() {
    super.initState();
    _showBriefing = kRoleplayBriefingLevels.contains(widget.level);
  }

  @override
  void didUpdateWidget(covariant RoleplayBaseLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      setState(() {
        _showBriefing = kRoleplayBriefingLevels.contains(widget.level);
      });
    }
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  // ── Content builder ────────────────────────────────────────────────────

  Widget _buildContent(dynamic theme, bool isDark) {
    final padding = widget.disablePadding
        ? EdgeInsets.zero
        : EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom:
                (widget.isAnswered ? 200.h : 40.h) +
                MediaQuery.of(context).viewInsets.bottom,
          );

    // Constrain width on tablets / large screens.
    final column = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kRoleplayMaxContentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: theme.primaryColor,
              ),
            ).animate().fadeIn(),
            SizedBox(height: 8.h),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            SizedBox(height: 32.h),
            widget.child,
          ],
        ),
      ),
    );

    final padded = Padding(padding: padding, child: column);

    if (!widget.useScrolling) return padded;

    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: padded,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: (prev, curr) =>
          curr is RoleplayLoaded &&
          (prev is! RoleplayLoaded ||
              prev.livesRemaining != curr.livesRemaining),
      listener: (_, state) {
        if (state is! RoleplayLoaded) return;
        final justDroppedToLastLife =
            _lastLives == kRoleplayLowLifeThreshold &&
            state.livesRemaining == 1;
        if (justDroppedToLastLife && !_hasSpokenNudge) {
          _hasSpokenNudge = true;
          _nudgeTimer?.cancel();
          _nudgeTimer = Timer(kRoleplayNudgeDelay, () {
            if (mounted) {
              _ttsService.speak(context.tr('games.kids_nudge'));
              _hapticService.warning();
            }
          });
        }
        _lastLives = state.livesRemaining;
      },
      builder: (context, state) {
        if (state is RoleplayError) {
          return Scaffold(
            backgroundColor: theme.backgroundColors[1],
            body: GameErrorWidget(
              message: state.message,
              onRetry: () => context.read<RoleplayBloc>().add(
                FetchRoleplayQuests(
                  gameType: widget.gameType,
                  level: widget.level,
                ),
              ),
              onBack: () => Navigator.pop(context),
              primaryColor: theme.primaryColor,
            ),
          );
        }

        double calculateProgress() {
          if (state is RoleplayLoaded) {
            final s = state;
            return (s.currentIndex + 1) / s.quests.length;
          }
          if (state is RoleplayGameComplete) return 1.0;
          return 0.0;
        }

        final progress = calculateProgress();
        final lives = state is RoleplayLoaded
            ? state.livesRemaining
            : kRoleplayDefaultLives;
        final quest = state is RoleplayLoaded ? state.currentQuest : null;
        final isComplete = state is RoleplayGameComplete;

        return PopScope(
          canPop: isComplete,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            GameDialogHelper.showExitConfirmation(
              context,
              onQuit: () => Navigator.of(context).pop(),
            );
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: theme.backgroundColors[1],
            body: Stack(
              children: [
                ColoredBox(color: theme.backgroundColors[1]),
                MeshGradientBackground(colors: theme.backgroundColors),
                // Isolated wave animation — does not repaint parent layers.
                RepaintBoundary(
                  child: HarmonicWaves(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    height: 150.h,
                  ),
                ),
                if (state is RoleplayLoading)
                  GameShimmerLoading(primaryColor: theme.primaryColor)
                else
                  SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        _buildHeader(
                          context,
                          state,
                          theme,
                          isDark,
                          lives,
                          progress,
                          quest,
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
                                  child: _buildContent(theme, isDark),
                                ),
                              ),
                              Positioned(
                                top: -10.h,
                                right: 10.w,
                                child: RoleplayPeekingMascot(
                                  state: state,
                                  lives: lives,
                                  isCorrect: widget.isCorrect,
                                  isAnswered: widget.isAnswered,
                                  mascotId: widget.mascotId,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.isAnswered &&
                    state is! RoleplayGameOver &&
                    state is! RoleplayGameComplete)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: RoleplayFeedbackCard(
                      state: state,
                      lives: lives,
                      isCorrect: widget.isCorrect,
                      isDark: isDark,
                      onContinue: widget.onContinue,
                    ),
                  ),
                if (widget.showConfetti) const GameConfetti(),
                if (_showBriefing) _buildBriefingOverlay(context, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    RoleplayState state,
    dynamic theme,
    bool isDark,
    int lives,
    double progress,
    dynamic quest,
  ) {
    final hintShouldGlow =
        lives < kRoleplayLowLifeThreshold && !widget.isAnswered;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: GameProgressHeader(
              level: widget.level,
              progress: progress,
              lives: lives,
              streak: state is RoleplayLoaded ? state.currentIndex : 0,
              theme: theme,
              isDark: isDark,
              onBack: () => GameDialogHelper.showExitConfirmation(
                context,
                onQuit: () => Navigator.pop(context),
              ),
            ),
          ),
          if (quest != null && !widget.isAnswered) ...[
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Semantics(
                label: 'Show instructions',
                button: true,
                child: ScaleButton(
                  onTap: () => setState(() => _showBriefing = true),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16.r,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child:
                  QuestHintButton(
                        used: state is RoleplayLoaded ? state.hintUsed : false,
                        primaryColor: theme.primaryColor,
                        hintText: quest.hint,
                        soundService: _soundService,
                        onTap: () {
                          context.read<RoleplayBloc>().add(
                            const RoleplayHintUsed(),
                          );
                          widget.onHint();
                        },
                      )
                      .animate(
                        target: hintShouldGlow ? 1 : 0,
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .shimmer(
                        color: Colors.white.withValues(alpha: 0.5),
                        duration: 1.seconds,
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                      ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Briefing overlay ───────────────────────────────────────────────────

  Widget _buildBriefingOverlay(BuildContext context, dynamic theme) {
    final briefing = GameInstructionService.getBriefing(
      context,
      widget.gameType,
      'Roleplay',
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
