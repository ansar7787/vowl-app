import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';

class WritingGameHeader extends StatelessWidget {
  final WritingState state;
  final int level;
  final double progress;
  final int lives;
  final bool isAnswered;
  final WritingQuest? quest;
  final dynamic theme;
  final bool isDark;
  final SoundService soundService;
  final VoidCallback onInfoTap;
  final VoidCallback onHint;

  const WritingGameHeader({
    super.key,
    required this.state,
    required this.level,
    required this.progress,
    required this.lives,
    required this.isAnswered,
    required this.quest,
    required this.theme,
    required this.isDark,
    required this.soundService,
    required this.onInfoTap,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final hintShouldGlow = lives < 3 && !isAnswered;
    final hintUsed = state is WritingLoaded
        ? (state as WritingLoaded).hintUsed
        : false;
    final streak = state is WritingLoaded
        ? (state as WritingLoaded).currentIndex
        : 0;

    return Padding(
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
              // FIX 1: Removed Semantics() wrapper that was incorrectly placed
              // inside the VoidCallback body. showExitConfirmation() returns
              // void — Semantics(child: void) is not valid. The back button's
              // own Semantics label belongs inside GameProgressHeader itself.
              onBack: () => GameDialogHelper.showExitConfirmation(
                context,
                onQuit: () => Navigator.pop(context),
              ),
            ),
          ),
          if (quest != null && !isAnswered) ...[
            SizedBox(width: 8.w),
            _InfoButton(theme: theme, onTap: onInfoTap),
            SizedBox(width: 8.w),
            _HintButton(
              hintUsed: hintUsed,
              hintText: quest!.hint,
              theme: theme,
              soundService: soundService,
              shouldGlow: hintShouldGlow,
              // onTap is always a real callback here; _HintButton decides
              // internally whether to forward it or suppress it.
              onTap: () {
                context.read<WritingBloc>().add(const WritingHintUsed());
                onHint();
              },
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _InfoButton extends StatelessWidget {
  final dynamic theme;
  final VoidCallback onTap;

  const _InfoButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Show game instructions',
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
          child: ExcludeSemantics(
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
  final bool hintUsed;
  final String? hintText;
  final dynamic theme;
  final SoundService soundService;
  final bool shouldGlow;

  // onTap stays non-nullable — the caller always supplies a real callback.
  // QuestHintButton.onTap is VoidCallback (non-nullable), so null can never
  // be passed to it. We suppress the callback by passing a no-op () {} when
  // the hint is already used; QuestHintButton's `used` flag handles the
  // disabled visual state independently.
  final VoidCallback onTap;

  const _HintButton({
    required this.hintUsed,
    required this.hintText,
    required this.theme,
    required this.soundService,
    required this.shouldGlow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: hintUsed ? 'Hint already used' : 'Use hint',
      button: !hintUsed,
      child:
          QuestHintButton(
                used: hintUsed,
                primaryColor: theme.primaryColor,
                hintText: hintText,
                soundService: soundService,
                // FIX: QuestHintButton.onTap is VoidCallback (non-nullable).
                // Pass a no-op when used — never null. The `used: hintUsed` flag
                // already disables the button visually; this just ensures the
                // callback slot satisfies the non-nullable type contract.
                onTap: hintUsed ? () {} : onTap,
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
    );
  }
}
