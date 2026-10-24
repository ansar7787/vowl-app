import 'package:vowl/core/utils/hint_utility.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Clean, stateless interactive hint button providing TTS-enabled hints,
/// ad-backed rewarded hints, and visual status badges.
///
/// Features:
/// - Re-reviewable: Tapping an already-used hint button replays the hint
///   (sound, TTS, and snackbar) without deducting extra hints.
/// - Premium-ready: Premium users receive instant hint access without ad paywalls.
/// - Race-condition safe: Debounced via [ScaleButton] and synchronized with Firestore.
class QuestHintButton extends StatelessWidget {
  final bool used;
  final Color primaryColor;
  final String? hintText;
  final VoidCallback onTap;
  final SoundService soundService;

  const QuestHintButton({
    super.key,
    required this.used,
    required this.primaryColor,
    this.hintText,
    required this.onTap,
    required this.soundService,
  });

  static void _showHintFeedback({
    required BuildContext context,
    required String? hintText,
    required SoundService soundService,
  }) {
    soundService.playHint();

    if (hintText != null && hintText.trim().isNotEmpty) {
      final isDynamic = HintUtility.isGenericHint(hintText);
      final displayText = isDynamic
          ? context.tr(
              'hint.pro_tip_generic',
              fallback: 'Look for context clues to help find the right answer.',
            )
          : hintText.trim();

      try {
        di.sl<TtsService>().stop();
        di.sl<TtsService>().speak(
          isDynamic
              ? context.tr(
                  'hint.pro_tip_tts',
                  fallback: 'Look for context clues.',
                )
              : hintText.trim(),
        );
      } catch (_) {}

      CustomSnackBar.show(
        context: context,
        message: displayText,
        type: CustomSnackBarType.info,
        duration: const Duration(seconds: 8),
      );
    }
  }

  void _handleTap(
    BuildContext context, {
    required int hintCount,
    required bool isPremium,
  }) {
    if (used) {
      // Re-review the hint for the current question without consuming any hint
      _showHintFeedback(
        context: context,
        hintText: hintText,
        soundService: soundService,
      );
      return;
    }

    final canUseHint = hintCount > 0 || isPremium;
    if (canUseHint) {
      onTap();
      _showHintFeedback(
        context: context,
        hintText: hintText,
        soundService: soundService,
      );
    } else {
      GameDialogHelper.showHintAdDialog(
        context,
        onHintEarned: () {
          if (!context.mounted) return;
          onTap();
          _showHintFeedback(
            context: context,
            hintText: hintText,
            soundService: soundService,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final hintCount = state.user?.hintCount ?? 0;
        final isPremium = state.user?.isPremium ?? false;
        final canUseHint = hintCount > 0 || isPremium;

        return Semantics(
          button: true,
          enabled: true,
          label: used
              ? context.tr('hint.review_hint_semantic', fallback: 'Review hint')
              : canUseHint
              ? (isPremium
                    ? context.tr(
                        'hint.use_hint_premium_semantic',
                        fallback: 'Use hint',
                      )
                    : context.tr(
                        'hint.use_hint_semantic',
                        args: ['$hintCount'],
                        fallback: 'Use hint ($hintCount remaining)',
                      ))
              : context.tr(
                  'hint.watch_ad_semantic',
                  fallback: 'Watch video to unlock a hint',
                ),
          child: ScaleButton(
            debounceDuration: const Duration(milliseconds: 1000),
            onTap: () =>
                _handleTap(context, hintCount: hintCount, isPremium: isPremium),
            child: RepaintBoundary(
              child: Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: used
                      ? Colors.grey.withValues(alpha: 0.08)
                      : canUseHint
                      ? primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: used
                        ? Colors.grey.withValues(alpha: 0.3)
                        : canUseHint
                        ? primaryColor.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    if (!used && canUseHint)
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main icon
                    Icon(
                          used
                              ? Icons.psychology_outlined
                              : (canUseHint
                                    ? Icons.lightbulb_rounded
                                    : Icons.video_collection_rounded),
                          color: used
                              ? Colors.grey
                              : (canUseHint ? primaryColor : Colors.amber[700]),
                          size: 26.r,
                        )
                        .animate(
                          target: VowlMotion.shouldReduceMotion(context) || used
                              ? 0
                              : 1,
                          onPlay: (c) =>
                              used ? c.stop() : c.repeat(reverse: true),
                        )
                        .shimmer(
                          duration: 2.seconds,
                          color: primaryColor.withValues(alpha: 0.3),
                        ),

                    // Hint count badge (when hints available and not yet used)
                    if (!used && !isPremium && hintCount > 0)
                      Positioned(
                        top: 2.r,
                        right: 2.r,
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16.r,
                            minHeight: 16.r,
                          ),
                          child: Center(
                            child: Text(
                              '$hintCount',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Ad badge (when 0 hints and free user)
                    if (!used && hintCount == 0 && !isPremium)
                      Positioned(
                        bottom: 4.r,
                        right: 4.r,
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: BoxDecoration(
                            color: AppColors.amber500,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 10.r,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
