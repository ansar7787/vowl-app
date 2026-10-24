import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

/// Game header bar containing: back button, progress bar, life hearts,
/// optional info button, and optional hint button.
///
/// Every interactive element carries a [Semantics] label.
class SpeakingGameHeader extends StatelessWidget {
  /// Current difficulty level.
  final int level;

  /// Normalized quest progression fraction (0.0 to 1.0).
  final double progress;

  /// Remaining lives count.
  final int lives;

  /// Current consecutive answer streak count.
  final int streak;

  /// Active speaking quest entity.
  final SpeakingQuest? quest;

  /// Whether user submission has been locked in.
  final bool isAnswered;

  /// Whether a pedagogical hint has been unlocked.
  final bool hintUsed;

  /// Acoustic cue sound service.
  final SoundService soundService;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether the hint action button is rendered.
  final bool showHintButton;

  /// Callback executed when tapping the back button.
  final VoidCallback onBack;

  /// Callback executed when triggering the hint action.
  final VoidCallback onHintTap;

  /// Callback executed when opening the quest instruction briefing.
  final VoidCallback onInfoTap;

  /// Creates a [SpeakingGameHeader].
  const SpeakingGameHeader({
    super.key,
    required this.level,
    required this.progress,
    required this.lives,
    required this.streak,
    required this.quest,
    required this.isAnswered,
    required this.hintUsed,
    required this.soundService,
    required this.isDark,
    this.showHintButton = true,
    required this.onBack,
    required this.onHintTap,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final showQuestControls = quest != null && !isAnswered;
    final hintShouldGlow = lives < 3 && !isAnswered;

    final rawTheme = LevelThemeHelper.getTheme('speaking', level: level);
    final Color primaryColor = rawTheme.primaryColor;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: GameProgressHeader(
              level: level,
              progress: progress,
              lives: lives,
              theme: rawTheme,
              isDark: isDark,
              onBack: onBack,
            ),
          ),
          if (showQuestControls) ...[
            SizedBox(width: 8.w),
            _InfoButton(primaryColor: primaryColor, onTap: onInfoTap),
            SizedBox(width: 8.w),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHintButton) ...[
                  _HintButton(
                    hintUsed: hintUsed,
                    hintShouldGlow: hintShouldGlow,
                    primaryColor: primaryColor,
                    hintText: quest!.hint,
                    soundService: soundService,
                    onTap: onHintTap,
                  ),
                  if (quest!.hint != null && hintUsed) ...[
                    SizedBox(width: 8.w),
                    TranslateButtonWidget(
                      originalText: quest!.hint!,
                      onTranslationComplete: (translated) {
                        CustomSnackBar.show(
                          context: context,
                          message: translated,
                          type: CustomSnackBarType.info,
                          duration: const Duration(seconds: 8),
                        );
                      },
                    ),
                  ],
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
// Sub-widgets (private)
// ---------------------------------------------------------------------------

class _InfoButton extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onTap;

  const _InfoButton({required this.primaryColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View level instructions',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: ExcludeSemantics(
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

class _HintButton extends StatelessWidget {
  final bool hintUsed;
  final bool hintShouldGlow;
  final Color primaryColor;
  final String? hintText;
  final SoundService soundService;
  final VoidCallback onTap;

  const _HintButton({
    required this.hintUsed,
    required this.hintShouldGlow,
    required this.primaryColor,
    required this.hintText,
    required this.soundService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget button = QuestHintButton(
      used: hintUsed,
      primaryColor: primaryColor,
      hintText: hintText,
      soundService: soundService,
      onTap: () {
        context.read<SpeakingBloc>().add(const SpeakingHintUsed());
        onTap();
      },
    );

    if (hintShouldGlow && !reduceMotion) {
      button = button
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            color: Colors.white.withValues(alpha: 0.5),
            duration: 1.seconds,
          )
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1));
    }

    return Semantics(
      button: true,
      enabled: !hintUsed,
      label: hintUsed ? 'Hint already used' : 'Use a hint for this question',
      child: button,
    );
  }
}
