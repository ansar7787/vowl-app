import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/bloc/game_state_base.dart';
import 'package:vowl/core/presentation/painters/visual_config_background.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

class GameScaffold<S> extends StatelessWidget {
  final S state;
  final GameStateBase baseState;
  final GameScaffoldConfig config;

  final Widget Function(
    BuildContext context,
    S state,
    double progress,
    int lives,
  )
  headerBuilder;
  final Widget Function(BuildContext context, S state)? feedbackBuilder;
  final Widget Function(BuildContext context, S state, int lives)?
  mascotBuilder;
  final Widget? backgroundOverlay;

  final bool showBriefing;
  final VoidCallback onBriefingDismiss;
  final VoidCallback onBriefingShow;
  final VoidCallback onExitPressed;
  final VoidCallback onRetry;

  const GameScaffold({
    super.key,
    required this.state,
    required this.baseState,
    required this.config,
    required this.headerBuilder,
    this.feedbackBuilder,
    this.mascotBuilder,
    this.backgroundOverlay,
    required this.showBriefing,
    required this.onBriefingDismiss,
    required this.onBriefingShow,
    required this.onExitPressed,
    required this.onRetry,
  });

  double get _progress {
    if (baseState is GameLoadedState) {
      final s = baseState as GameLoadedState;
      if (s.totalQuests == 0) return 0.0;
      return (s.currentIndex + 1) / s.totalQuests;
    }
    return baseState is GameCompleteState ? 1.0 : 0.0;
  }

  int get _lives => baseState.livesRemaining;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Default theme mapping; category specifics can still override internally if needed
    final theme = LevelThemeHelper.getTheme(
      config.gameType.name,
      isDark: isDark,
      level: config.level,
    );

    final currentQuest = baseState is GameLoadedState
        ? (baseState as GameLoadedState).currentQuestOrNull
        : null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.backgroundColors[1],
      body: Stack(
        children: [
          // ── Layer 1: Background ─────────────────────────────────────────
          ColoredBox(color: theme.backgroundColors[1]),
          MeshGradientBackground(colors: theme.backgroundColors),

          ?backgroundOverlay,

          if (currentQuest?.visualConfig != null)
            Positioned.fill(
              child: RepaintBoundary(
                child: VisualConfigBackground(
                  config: currentQuest!.visualConfig!,
                ),
              ),
            ),

          // ── Layer 2: Content, Loading, or Error ─────────────────────────
          if (baseState is GameErrorState)
            GameErrorView(
              message: (baseState as GameErrorState).message,
              primaryColor: theme.primaryColor,
              onRetry: onRetry,
            )
          else if (baseState is GameLoadingState ||
              baseState is GameInitialState)
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    // Header shimmer
                    ShimmerLoading.rounded(
                      width: double.infinity,
                      height: 60.h,
                      borderRadius: 16,
                    ),
                    SizedBox(height: 32.h),
                    // Content block shimmer
                    Expanded(
                      child: ShimmerLoading.rounded(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 24,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    // Bottom button/feedback shimmer
                    ShimmerLoading.rounded(
                      width: double.infinity,
                      height: 72.h,
                      borderRadius: 16,
                    ),
                  ],
                ),
              ),
            )
          else
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  headerBuilder(context, state, _progress, _lives),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AbsorbPointer(
                          absorbing: config.isAnswered,
                          child: config.disablePadding
                              ? config.child
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: config.useScrolling
                                      ? SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: config.child,
                                        )
                                      : config.child,
                                ),
                        ),
                        if (mascotBuilder != null)
                          Positioned(
                            top: -10.h,
                            right: 20.w,
                            child: mascotBuilder!(context, state, _lives),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Layer 3: Feedback Card ──────────────────────────────────────
          if (config.isAnswered &&
              config.isCorrect != null &&
              baseState is! GameOverState &&
              baseState is! GameCompleteState &&
              feedbackBuilder != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: feedbackBuilder!(context, state),
            ),

          // ── Layer 4: Briefing Overlay ───────────────────────────────────
          if (showBriefing)
            GameBriefingLayer(
              gameType: config.gameType,
              level: config.level,
              theme: theme,
              onStart: onBriefingDismiss,
            ),

          // ── Layer 5: Confetti ───────────────────────────────────────────
          if (config.showConfetti) const GameConfetti(),
        ],
      ),
    );
  }
}
