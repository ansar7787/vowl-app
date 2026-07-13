import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';

/// Top navigation and progress bar for the listening game.
///
/// Renders [GameProgressHeader] (progress / lives / back button) plus an optional
/// info button and an animated hint button shown when the question is active.
class ListeningHeader extends StatelessWidget {
  final int level;
  final double progress;
  final int lives;
  final ListeningState state;
  final dynamic quest;
  final dynamic theme;
  final bool isDark;
  final bool isAnswered;
  final SoundService soundService;
  final VoidCallback onHint;
  final VoidCallback onShowBriefing;
  final VoidCallback onBack;

  const ListeningHeader({
    super.key,
    required this.level,
    required this.progress,
    required this.lives,
    required this.state,
    required this.quest,
    required this.theme,
    required this.isDark,
    required this.isAnswered,
    required this.soundService,
    required this.onHint,
    required this.onShowBriefing,
    required this.onBack,
  });

  bool get _hintShouldGlow => lives < 3 && !isAnswered;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Game header — level $level, $lives ${lives == 1 ? "life" : "lives"} remaining',
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
            if (quest != null && !isAnswered) ...[
              _InfoButton(theme: theme, onTap: onShowBriefing),
              SizedBox(width: 8.w),
              _HintButton(
                state: state,
                theme: theme,
                quest: quest,
                soundService: soundService,
                lives: lives,
                isAnswered: isAnswered,
                shouldGlow: _hintShouldGlow,
                onHint: onHint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoButton extends StatelessWidget {
  final dynamic theme;
  final VoidCallback onTap;

  const _InfoButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Show level instructions',
      child: Padding(
        padding: EdgeInsets.only(left: 8.w),
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

// ─────────────────────────────────────────────────────────────────────────────

class _HintButton extends StatelessWidget {
  final ListeningState state;
  final dynamic theme;
  final dynamic quest;
  final SoundService soundService;
  final int lives;
  final bool isAnswered;
  final bool shouldGlow;
  final VoidCallback onHint;

  const _HintButton({
    required this.state,
    required this.theme,
    required this.quest,
    required this.soundService,
    required this.lives,
    required this.isAnswered,
    required this.shouldGlow,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final used = state is ListeningLoaded
        ? (state as ListeningLoaded).hintUsed
        : false;
    return Semantics(
      button: true,
      label: used ? 'Hint already used' : 'Use hint',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuestHintButton(
                used: used,
                primaryColor: theme.primaryColor,
                // Suppress the generic JSON text hint for Listening games.
                // Instead, the BaseLayout intercepts this to visually
                // show a custom snackbar and auto-replay the audio track.
                hintText: null,
                soundService: soundService,
                onTap: onHint,
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
          if (quest.hint != null) ...[
            SizedBox(width: 8.w),
            TranslateButtonWidget(
              originalText: quest.hint,
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
    );
  }
}
