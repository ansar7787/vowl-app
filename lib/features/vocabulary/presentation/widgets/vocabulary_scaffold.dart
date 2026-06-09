import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/painters/visual_config_background.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/pages/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_header.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_body_area.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_peeking_mascot.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_feedback_card.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_briefing_layer.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_error_view.dart';

class VocabularyScaffold extends StatelessWidget {
  final VocabularyState state;
  final dynamic theme;
  final bool isDark;
  final VocabularyBaseLayout config;
  final bool showBriefing;
  final VoidCallback onBriefingDismiss;
  final VoidCallback onBriefingShow;
  final VoidCallback onExitPressed;

  const VocabularyScaffold({
    super.key,
    required this.state,
    required this.theme,
    required this.isDark,
    required this.config,
    required this.showBriefing,
    required this.onBriefingDismiss,
    required this.onBriefingShow,
    required this.onExitPressed,
  });

  double get _progress {
    if (state is VocabularyLoaded) {
      final s = state as VocabularyLoaded;
      return (s.currentIndex + 1) / s.quests.length;
    }
    return state is VocabularyGameComplete ? 1.0 : 0.0;
  }

  int get _lives => state is VocabularyLoaded
      ? (state as VocabularyLoaded).livesRemaining
      : 3;

  @override
  Widget build(BuildContext context) {
    final currentQuest = state is VocabularyLoaded
        ? (state as VocabularyLoaded).currentQuestOrNull
        : null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.backgroundColors[1] as Color,
      body: Stack(
        children: [
          // ── Layer 1: Background ──────────────────────────────
          Container(color: theme.backgroundColors[1] as Color),
          MeshGradientBackground(colors: theme.backgroundColors as List<Color>),
          if (currentQuest?.visualConfig != null)
            Positioned.fill(
              child: RepaintBoundary(
                child: VisualConfigBackground(
                  config: currentQuest!.visualConfig!,
                ),
              ),
            ),

          // ── Layer 2: Content or Error ────────────────────────
          if (state is VocabularyError)
            VocabularyErrorView(
              message: (state as VocabularyError).message,
              primaryColor: theme.primaryColor as Color,
              onRetry: () => context.read<VocabularyBloc>().add(
                FetchVocabularyQuests(
                  gameType: config.gameType,
                  level: config.level,
                ),
              ),
            )
          else
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  VocabularyHeader(
                    state: state,
                    level: config.level,
                    progress: _progress,
                    lives: _lives,
                    theme: theme,
                    isDark: isDark,
                    isAnswered: config.isAnswered,
                    gameType: config.gameType,
                    onExit: onExitPressed,
                    onBriefingShow: onBriefingShow,
                    onHint: config.onHint,
                  ),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AbsorbPointer(
                          absorbing: config.isAnswered,
                          child: VocabularyBodyArea(
                            isAnswered: config.isAnswered,
                            useScrolling: config.useScrolling,
                            disablePadding: config.disablePadding,
                            child: config.child,
                          ),
                        ),
                        Positioned(
                          top: -10.h,
                          left: 20.w,
                          child: VocabularyPeekingMascot(
                            state: state,
                            lives: _lives,
                            isCorrect: config.isCorrect,
                            isAnswered: config.isAnswered,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Layer 3: Feedback Card ───────────────────────────
          if (config.isAnswered &&
              config.isCorrect != null &&
              state is! VocabularyGameOver &&
              state is! VocabularyGameComplete)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VocabularyFeedbackCard(
                state: state,
                theme: theme,
                isDark: isDark,
                isCorrect: config.isCorrect,
                isFinalFailure: config.isFinalFailure,
                onContinue: config.onContinue,
              ),
            ),

          // ── Layer 4: Briefing Overlay ────────────────────────
          if (showBriefing)
            VocabularyBriefingLayer(
              gameType: config.gameType,
              level: config.level,
              theme: theme,
              onStart: onBriefingDismiss,
            ),

          // ── Layer 5: Confetti ────────────────────────────────
          if (config.showConfetti) const GameConfetti(),
        ],
      ),
    );
  }
}
