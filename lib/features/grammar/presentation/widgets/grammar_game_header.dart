import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';

/// Top bar for grammar quiz screens.
///
/// Renders the level progress header ([GameProgressHeader]) and, when there is
/// an active unanswered quest, appends the info-toggle and hint buttons.
class GrammarGameHeader extends StatelessWidget {
  final GrammarState state;
  final int level;
  final double progress;
  final int lives;

  /// : Replace `dynamic` with the concrete return type of
  /// `LevelThemeHelper.getTheme()` once that file is in scope.
  final dynamic theme;

  /// The current quest, if any. When null (loading / complete), action
  /// buttons are hidden.
  final GrammarQuest? quest;

  final bool isAnswered;
  final bool isFinalFailure;
  final SoundService soundService;

  /// Called when the user taps the ℹ info button to show the level briefing.
  final VoidCallback onShowBriefing;

  /// Called when the user activates the hint. Parallel to [GrammarHintUsed]
  /// event which is dispatched internally.
  final VoidCallback onHint;

  const GrammarGameHeader({
    super.key,
    required this.state,
    required this.level,
    required this.progress,
    required this.lives,
    required this.theme,
    required this.quest,
    required this.isAnswered,
    required this.isFinalFailure,
    required this.soundService,
    required this.onShowBriefing,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final isLoaded = state is GrammarLoaded;
    final hintShouldGlow = lives < 3 && !isAnswered;
    final showActions = quest != null && !isAnswered;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        children: [
          Expanded(
            child: GameProgressHeader(
              level: level,
              progress: progress,
              lives: lives,
              streak: isLoaded ? (state as GrammarLoaded).currentIndex : 0,
              theme: theme,
              isDark: Theme.of(context).brightness == Brightness.dark,
              onBack: onShowBriefing,
            ),
          ),
          if (showActions) ...[
            SizedBox(width: 8.w),
            _InfoButton(
              primaryColor: theme.primaryColor as Color,
              onTap: onShowBriefing,
            ),
            SizedBox(width: 8.w),
            _HintButton(
              state: state,
              quest: quest!,
              isLoaded: isLoaded,
              isFinalFailure: isFinalFailure,
              hintShouldGlow: hintShouldGlow,
              primaryColor: theme.primaryColor as Color,
              soundService: soundService,
              onHint: onHint,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _InfoButton extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onTap;

  const _InfoButton({required this.primaryColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Show level instructions',
      button: true,
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16.r,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}

class _HintButton extends StatelessWidget {
  final GrammarState state;
  final GrammarQuest quest;
  final bool isLoaded;
  final bool isFinalFailure;
  final bool hintShouldGlow;
  final Color primaryColor;
  final SoundService soundService;
  final VoidCallback onHint;

  const _HintButton({
    required this.state,
    required this.quest,
    required this.isLoaded,
    required this.isFinalFailure,
    required this.hintShouldGlow,
    required this.primaryColor,
    required this.soundService,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    // Safe: caller guarantees state is GrammarLoaded when quest != null.
    final hintUsed = isFinalFailure
        ? false
        : (isLoaded ? (state as GrammarLoaded).hintUsed : false);

    return QuestHintButton(
          used: hintUsed,
          primaryColor: primaryColor,
          hintText: quest.hint,
          soundService: soundService,
          onTap: () {
            context.read<GrammarBloc>().add(const GrammarHintUsed());
            onHint();
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
        .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1));
  }
}
