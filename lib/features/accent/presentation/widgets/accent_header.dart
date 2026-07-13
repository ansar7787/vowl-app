import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';

/// Header bar for the Accent game screen.
///
/// Fully decoupled from [AccentBloc] — all state is passed in, all actions
/// are expressed as callbacks. This makes the widget independently testable
/// and reusable.
///
/// The theme is resolved internally via [LevelThemeHelper.getTheme] so the
/// caller never needs to know (or name) the return type of that method.
/// [GameProgressHeader] receives the raw inferred-type object directly, which
/// satisfies its parameter without an explicit cast.
class AccentHeader extends StatelessWidget {
  final int level;
  final double progress;
  final int lives;
  final int streak;
  final bool isDark;

  /// Current quest, or `null` when the level is loading / complete.
  final AccentQuest? quest;

  /// If `true`, the hint and briefing buttons are hidden (answer is locked).
  final bool isAnswered;

  final bool hintUsed;
  final SoundService soundService;

  final VoidCallback onBack;
  final VoidCallback onShowBriefing;
  final VoidCallback onHintTap;

  const AccentHeader({
    super.key,
    required this.level,
    required this.progress,
    required this.lives,
    required this.streak,
    required this.isDark,
    required this.quest,
    required this.isAnswered,
    required this.hintUsed,
    required this.soundService,
    required this.onBack,
    required this.onShowBriefing,
    required this.onHintTap,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve once per build via Dart type inference.
    // The return type of getTheme() is inferred — we never write 'LevelTheme'
    // explicitly, so the "Undefined class" error cannot occur here.
    final rawTheme = LevelThemeHelper.getTheme('accent', level: level);

    // Extract the one primitive we need for our own widgets.
    final Color primaryColor = rawTheme.primaryColor;

    final showActions = quest != null && !isAnswered;
    final hintShouldGlow = lives < 3 && !isAnswered && !hintUsed;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            // rawTheme satisfies GameProgressHeader's `theme:` parameter because
            // both originate from the same LevelThemeHelper.getTheme() call.
            child: GameProgressHeader(
              level: level,
              progress: progress,
              lives: lives,
              streak: streak,
              theme: rawTheme,
              isDark: isDark,
              onBack: onBack,
            ),
          ),
          if (showActions) ...[
            SizedBox(width: 8.w),
            _InfoButton(primaryColor: primaryColor, onTap: onShowBriefing),
            SizedBox(width: 8.w),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HintButton(
                  quest: quest!,
                  hintUsed: hintUsed,
                  primaryColor: primaryColor,
                  soundService: soundService,
                  shouldGlow: hintShouldGlow,
                  onTap: onHintTap,
                ),
                if (quest!.hint != null) ...[
                  SizedBox(width: 8.w),
                  TranslateButtonWidget(
                    originalText: quest!.hint!,
                    onTranslationComplete: (translated) {
                      CustomSnackBar.show(
                        context: context,
                        message: translated,
                        type: CustomSnackBarType.info,
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InfoButton — briefing trigger
// ---------------------------------------------------------------------------

class _InfoButton extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onTap;

  const _InfoButton({required this.primaryColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Show instructions',
      child: Semantics(
        label: 'Show instructions',
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HintButton — with shimmer glow when last life is at risk
// ---------------------------------------------------------------------------

class _HintButton extends StatelessWidget {
  final AccentQuest quest;
  final bool hintUsed;
  final Color primaryColor;
  final SoundService soundService;
  final bool shouldGlow;
  final VoidCallback onTap;

  const _HintButton({
    required this.quest,
    required this.hintUsed,
    required this.primaryColor,
    required this.soundService,
    required this.shouldGlow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hintUsed ? 'Hint already used' : 'Use hint',
      child: Semantics(
        label: hintUsed ? 'Hint already used' : 'Use hint',
        hint: 'Costs coins. Reveals a clue for the current question.',
        button: true,
        child:
            QuestHintButton(
                  used: hintUsed,
                  primaryColor: primaryColor,
                  hintText: quest.hint,
                  soundService: soundService,
                  onTap: onTap,
                )
                .animate(
                  target: shouldGlow ? 1 : 0,
                  onPlay: (c) => c.repeat(reverse: true),
                )
                .shimmer(
                  color: Colors.white.withValues(alpha: 0.5),
                  duration: 1.seconds,
                )
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
      ),
    );
  }
}
