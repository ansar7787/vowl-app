import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_content_body.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_feedback_card.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_header.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_peeking_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';

// ---------------------------------------------------------------------------
// AccentBaseLayout
// ---------------------------------------------------------------------------

/// Scaffold shell for all Accent game variants.
class AccentBaseLayout extends StatelessWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final VoidCallback? onTutorPass;
  final bool showConfetti;
  final String title;
  final String subtitle;
  final bool useScrolling;
  final bool disablePadding;

  const AccentBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.isCorrect,
    required this.onContinue,
    required this.onHint,
    this.onTutorPass,
    this.showConfetti = false,
    this.title = 'ACCENT TRAINING',
    this.subtitle = 'Master the Sound',
    this.useScrolling = false,
    this.disablePadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: level);
    
    // Subscribes only to vowlMascot changes — not every AuthState emission.
    final mascotId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.vowlMascot ?? 'vowl_prime',
    );

    final wrappedChild = AccentContentBody(
      useScrolling: useScrolling,
      disablePadding: disablePadding,
      isAnswered: isAnswered,
      title: title,
      subtitle: subtitle,
      primaryColor: theme.primaryColor,
      isDark: isDark,
      child: child,
    );

    final config = GameScaffoldConfig(
      gameType: gameType,
      level: level,
      child: wrappedChild,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      isFinalFailure: false, // Handled internally
      onContinue: onContinue,
      onHint: onHint,
      showConfetti: showConfetti,
      useScrolling: false, // Handled internally by AccentContentBody
      disablePadding: true, // Handled internally by AccentContentBody
    );

    return GameBaseLayout<AccentBloc, AccentState>(
      config: config,
      stateMapper: (s) => s,
      onRetry: () => context.read<AccentBloc>().add(
        FetchAccentQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () => context.read<AccentBloc>().add(const RestoreLife()),
      backgroundOverlay: ClipRect(
        child: HarmonicWaves(
          color: theme.primaryColor.withValues(alpha: 0.3),
          height: 150.h,
        ),
      ),
      headerBuilder: (context, state, progress, lives) {
        return AccentHeader(
          level: level,
          progress: progress,
          lives: lives,
          streak: state is AccentLoaded ? state.currentIndex : 0,
          isDark: isDark,
          quest: state is AccentLoaded ? state.currentQuestOrNull : null,
          isAnswered: isAnswered,
          hintUsed: state is AccentLoaded ? state.hintUsed : false,
          soundService: di.sl<SoundService>(),
          onBack: () => GameDialogHelper.showExitConfirmation(
            context,
            onQuit: () => Navigator.pop(context),
          ),
          onShowBriefing: () {}, // GameBaseLayout handles briefing
          onHintTap: () {
            context.read<AccentBloc>().add(const AccentHintUsed());
            onHint();
          },
        );
      },
      mascotBuilder: (context, state, lives) {
        return AccentPeekingMascot(
          state: state,
          lives: lives,
          mascotId: mascotId,
          isCorrect: isCorrect,
        );
      },
      feedbackBuilder: (context, state) {
        if (state is! AccentLoaded) return const SizedBox.shrink();
        return AccentFeedbackCard(
          state: state,
          isDark: isDark,
          isCorrect: isCorrect,
          onContinue: onContinue,
          onTutorPass: onTutorPass,
        );
      },
    );
  }
}
