import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';

/// Standalone header widget for the Elite Mastery game screen.
///
/// Extracted from [EliteBaseLayout] to:
///  - Make the header independently testable via `pumpWidget`.
///  - Limit rebuild scope: only rebuilds when its props change, not on every
///    BLoC state transition that doesn't affect the header.
///  - Allow `RepaintBoundary` placement around the hint-glow animation without
///    affecting the rest of the layout tree.
///
/// ## Theme parameter
/// [theme] is typed `dynamic` because `LevelTheme` is not yet exported from
/// `level_theme_helper.dart`. Replace with `LevelTheme` once available.
class EliteGameHeader extends StatelessWidget {
  /// Current level number — displayed in the header progress bar.
  final int level;

  /// Fractional progress through the current level's quest list (0.0–1.0).
  final double progress;

  /// Lives remaining — drives the hearts display and hint-glow trigger.
  final int lives;

  /// Answered-question streak — displayed alongside the progress bar.
  final int streak;

  /// Whether the current question has been answered.
  /// When `true`, the hint and briefing buttons are hidden.
  final bool isAnswered;

  /// Whether the player has already spent a hint on the current question.
  final bool isHintUsed;

  /// Hint text for the current quest.
  /// When `null`, the hint button is not shown.
  final String? hintText;

  // : Replace `dynamic` with `LevelTheme` once exported from
  // `level_theme_helper.dart`.
  final dynamic theme;

  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onHint;
  final VoidCallback onBriefing;

  // Mirror of EliteMasteryBloc._maxLives — kept in sync via constant review.
  // If the game design changes the max lives, update both values together.
  static const int _kMaxLives = 3;

  const EliteGameHeader({
    super.key,
    required this.level,
    required this.progress,
    required this.lives,
    required this.streak,
    required this.isAnswered,
    required this.isHintUsed,
    this.hintText,
    required this.theme,
    required this.isDark,
    required this.onBack,
    required this.onHint,
    required this.onBriefing,
  });

  @override
  Widget build(BuildContext context) {
    final hintShouldGlow = lives < _kMaxLives && !isAnswered;
    final showActions = hintText != null && !isAnswered;

    return Semantics(
      container: true,
      // Screen readers announce level and lives so the player can track
      // progress without visually inspecting the header.
      label: 'Level $level. $lives ${lives == 1 ? "life" : "lives"} remaining.',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            Expanded(
              child: GameProgressHeader(
                level: level,
                progress: progress,
                lives: lives,
                streak: streak,
                theme: theme,
                isDark: isDark,
                onBack: onBack,
              ),
            ),
            if (showActions) ...[
              _BriefingButton(theme: theme, onTap: onBriefing),
              SizedBox(width: 8.w),
              // RepaintBoundary: the shimmer/scale glow animation on the hint
              // button fires on a loop. Without the boundary, every animation
              // frame triggers a repaint of the entire header row.
              RepaintBoundary(
                child: _HintButton(
                  isHintUsed: isHintUsed,
                  hintText: hintText!,
                  primaryColor: theme.primaryColor,
                  hintShouldGlow: hintShouldGlow,
                  onTap: onHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ─────────────────────────────────────────────────────

class _BriefingButton extends StatelessWidget {
  final dynamic theme;
  final VoidCallback onTap;

  const _BriefingButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Semantics(
        label: 'Show level instructions',
        button: true,
        child: ScaleButton(
          onTap: onTap,
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
    );
  }
}

class _HintButton extends StatelessWidget {
  final bool isHintUsed;
  final String hintText;
  final Color primaryColor;
  final bool hintShouldGlow;
  final VoidCallback onTap;

  const _HintButton({
    required this.isHintUsed,
    required this.hintText,
    required this.primaryColor,
    required this.hintShouldGlow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isHintUsed ? 'Hint already used' : 'Show hint',
      button: true,
      child:
          QuestHintButton(
                used: isHintUsed,
                primaryColor: primaryColor,
                hintText: hintText,
                soundService: di.sl<SoundService>(),
                onTap: onTap,
              )
              .animate(
                target: hintShouldGlow ? 1 : 0,
                onPlay: (c) => c.repeat(reverse: true),
              )
              .shimmer(
                color: Colors.white.withValues(alpha: 0.5),
                duration: 1.seconds,
              )
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
    );
  }
}
