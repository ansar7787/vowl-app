import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

import 'package:vowl/core/presentation/painters/visual_config_background.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

import 'package:vowl/core/theme/theme_cubit.dart';

import 'package:vowl/features/elite_mastery/presentation/widgets/elite_feedback_card.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_game_header.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_peeking_mascot.dart';

import '../bloc/elite_mastery_bloc.dart';

import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

class EliteBaseLayout extends StatelessWidget {
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
  final VoidCallback? onTutorPass;

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
    this.onTutorPass,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.read<ThemeCubit>().state.isMidnight;
    final theme = LevelThemeHelper.getTheme(
      gameType.name,
      level: level,
      isDark: isDark,
      isMidnight: isMidnight,
    );
    final quest = state is EliteMasteryLoaded ? (state as EliteMasteryLoaded).currentQuest : null;

    final wrappedChild = Builder(builder: (context) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: (subtitle == null || subtitle!.isEmpty) ? 14.sp : 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: (subtitle == null || subtitle!.isEmpty) ? 0 : 4,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B).withValues(alpha: 0.7),
                  ),
                ),
              ).animate().fadeIn(),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),
              ],
              SizedBox(height: 32.h),
              child,
            ],
          ),
        ),
      );
    });

    final config = GameScaffoldConfig(
      gameType: gameType,
      level: level,
      child: wrappedChild,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      isFinalFailure: isFinalFailure,
      onContinue: onContinue,
      onHint: onHint,
      showConfetti: showConfetti,
      useScrolling: true,
      disablePadding: false,
    );

    return GameBaseLayout<EliteMasteryBloc, EliteMasteryState>(
      config: config,
      stateMapper: (s) => s,
      onRetry: () => context.read<EliteMasteryBloc>().add(
        FetchEliteMasteryQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () => context.read<EliteMasteryBloc>().add(const RestoreEliteLife()),
      backgroundOverlay: Builder(builder: (context) {
        return Stack(
          children: [
            if (visualConfig != null)
              VisualConfigBackground(config: visualConfig!)
            else if (quest?.visualConfig != null)
              VisualConfigBackground(config: quest!.visualConfig!),
          ],
        );
      }),
      headerBuilder: (context, dynamicState, progress, lives) {
        return EliteGameHeader(
          level: level,
          progress: progress,
          lives: lives,
          streak: dynamicState is EliteMasteryLoaded ? dynamicState.currentIndex : 0,
          isAnswered: isAnswered,
          isHintUsed: dynamicState is EliteMasteryLoaded ? dynamicState.isHintUsed : false,
          hintText: quest?.hint,
          theme: theme,
          isDark: isDark,
          onBack: () => GameDialogHelper.showExitConfirmation(
            context,
            onQuit: () => Navigator.pop(context),
          ),
          onHint: onHint,
          onBriefing: () {}, // GameBaseLayout handles briefing internally
        );
      },
      mascotBuilder: (context, dynamicState, lives) {
        return ElitePeekingMascot(
          state: dynamicState,
          lives: lives,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
        );
      },
      feedbackBuilder: (context, dynamicState) {
        if (dynamicState is! EliteMasteryLoaded) return const SizedBox.shrink();
        return EliteFeedbackCard(
          state: dynamicState,
          isCorrect: isCorrect,
          onContinue: onContinue,
          isDark: isDark,
          onTutorPass: onTutorPass,
        );
      },
    );
  }
}
