import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_game_header.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_peeking_mascot.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_voice_pulse_bg.dart';
import 'package:vowl/core/presentation/layout/game_base_layout.dart';
import 'package:vowl/core/presentation/models/game_scaffold_config.dart';
import 'package:vowl/core/presentation/bloc/game_state_base.dart';

// ---------------------------------------------------------------------------
// Layout constants
// ---------------------------------------------------------------------------

const int _kNudgeDelayMs = 1200;
const int _kBriefingTriggerLevel = 1;
const int _kBriefingTutorialLevel = 100;



// =============================================================================
// SpeakingBaseLayout
// =============================================================================

class SpeakingBaseLayout extends StatelessWidget {
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
  final VoidCallback? onTutorPass;
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
    this.onTutorPass,
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
  Widget build(BuildContext context) {
    final mascotId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.vowlMascot ?? 'vowl_prime',
    );
    final mascotName = mascotId
        .split('_')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');

    final config = GameScaffoldConfig(
      gameType: gameType,
      level: level,
      child: child,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      isFinalFailure: isFinalFailure,
      onContinue: onContinue,
      onHint: onHint,
      showConfetti: showConfetti,
      useScrolling: useScrolling,
      disablePadding: disablePadding,
    );

    return GameBaseLayout<SpeakingBloc, SpeakingState>(
      config: config,
      stateMapper: (s) => s,
      onRetry: () => context.read<SpeakingBloc>().add(
        FetchSpeakingQuests(gameType: gameType, level: level),
      ),
      onRestoreLife: () => context.read<SpeakingBloc>().add(const RestoreLife()),
      backgroundOverlay: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final theme = LevelThemeHelper.getTheme('speaking', level: level, isDark: isDark);
          return SpeakingVoicePulseBg(
            color: (theme.primaryColor as Color).withValues(alpha: 0.15),
          );
        },
      ),
      headerBuilder: (context, state, progress, lives) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final currentQuest = state is SpeakingLoaded ? state.currentQuestOrNull : null;
        final hintUsed = state is SpeakingLoaded ? state.hintUsed : false;
        final streak = state is SpeakingLoaded ? state.currentIndex : 0;
        
        return SpeakingGameHeader(
          level: level,
          progress: progress,
          lives: lives,
          streak: streak,
          quest: currentQuest,
          isAnswered: isAnswered,
          hintUsed: hintUsed,
          soundService: soundService ?? di.sl<SoundService>(),
          isDark: isDark,
          onBack: () => GameDialogHelper.showExitConfirmation(
            context,
            onQuit: () => Navigator.of(context).pop(),
          ),
          onHintTap: onHint,
          onInfoTap: () {}, // GameBaseLayout handles briefing
        );
      },
      mascotBuilder: (context, state, lives) {
        return SpeakingPeekingMascot(
          state: state,
          lives: lives,
          isCorrect: isCorrect,
          isAnswered: isAnswered,
          mascotId: mascotId,
          mascotName: mascotName,
        );
      },
      feedbackBuilder: (context, state) {
        if (state is! SpeakingLoaded) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = LevelThemeHelper.getTheme('speaking', level: level, isDark: isDark);
        
        final quest = state.currentQuest;
        String? explanation = quest.explanation;
        if (explanation == null && isCorrect == false && isFinalFailure) {
           if (quest.correctAnswerIndex != null && quest.options != null && quest.options!.isNotEmpty) {
               explanation = quest.options![quest.correctAnswerIndex!];
           }
        }

        return GameFeedbackCard(
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          livesRemaining: state.livesRemaining,
          onContinue: onContinue,
          isDark: isDark,
          primaryColor: theme.primaryColor as Color,
          explanation: explanation,
          onTutorPass: onTutorPass,
        );
      },
    );
  }
}
