import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Standalone header widget for the Elite Mastery game screen.
///
/// Extracted from [EliteBaseLayout] to:
///  - Make the header independently testable via `pumpWidget`.
///  - Limit rebuild scope: only rebuilds when its props change, not on every
///    BLoC state transition that doesn't affect the header.
///  - Allow `RepaintBoundary` placement around the hint-glow animation without
///    affecting the rest of the layout tree.
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

  final ThemeResult theme;

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
      // FIX: previously a hardcoded English string, the only one of its
      // kind in this file — every other user-facing/semantic string here
      // and elsewhere in this feature goes through `context.tr(...)`. A
      // screen-reader user on any of this app's other 17 supported
      // languages would hear this one announcement in English regardless
      // of their device locale. NOTE: `games.semantic_level_progress` is a
      // new localization key needed in the ARB/localization files (outside
      // this feature slice); its English text should itself handle the
      // life/lives plural, e.g. via that framework's plural syntax if
      // supported, or two args as used here in the interim.
      label: context.tr(
        'games.semantic_level_progress',
        fallback: 'Level Progress',
        args: [level.toString(), lives.toString()],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            Expanded(
              child: GameProgressHeader(
                level: level,
                progress: progress,
                lives: lives,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HintButton(
                      isHintUsed: isHintUsed,
                      hintText: hintText!,
                      primaryColor: theme.primaryColor,
                      hintShouldGlow: hintShouldGlow,
                      onTap: onHint,
                    ),
                    SizedBox(width: 8.w),
                    TranslateButtonWidget(
                      originalText: hintText!,
                      onTranslationComplete: (translated) {
                        CustomSnackBar.show(
                          context: context,
                          message: translated,
                          type: CustomSnackBarType.info,
                        );
                      },
                    ),
                  ],
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
  final ThemeResult theme;
  final VoidCallback onTap;

  const _BriefingButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // FIX: was `EdgeInsets.only(left: 8.w)` — a literal side that does not
      // flip when this Row's layout direction mirrors for RTL locales
      // (Arabic). `EdgeInsetsDirectional.only(start:)` keeps this spacing on
      // the correct side of the button regardless of text direction.
      padding: EdgeInsetsDirectional.only(start: 8.w),
      child: Semantics(
        label: context.tr(
          'games.semantic_show_instructions',
          fallback: 'Show Instructions',
        ),
        button: true,
        child: ScaleButton(
          onTap: onTap,
          // FIX: the visible circle (6.r padding + 16.r icon ≈ 28 logical
          // px) sits well under the 48x48dp minimum touch-target
          // recommendation. Wrapping it in an invisible 48x48 box (centered)
          // grows only the tappable area — the visible circle itself is
          // completely unchanged — assuming `ScaleButton` hit-tests the
          // full space given to its child, which is the standard behavior
          // for this kind of button wrapper; worth confirming directly
          // against `scale_button.dart` if available.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(
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
      // FIX: another hardcoded English pair found alongside the ones fixed
      // above — same issue, same fix. NOTE: `games.semantic_hint_used` /
      // `games.semantic_show_hint` are new localization keys needed in the
      // ARB/localization files (outside this feature slice).
      label: isHintUsed
          ? context.tr('games.semantic_hint_used', fallback: 'Hint Used')
          : context.tr('games.semantic_show_hint', fallback: 'Show Hint'),
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
