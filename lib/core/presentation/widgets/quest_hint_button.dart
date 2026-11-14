import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/hint_utility.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

/// Cohesive, unified horizontal hint capsule providing zero-latency (0ms)
/// hint deduction, rewarded ads for free users with 0 hints, and unlimited
/// hint access for premium users.
///
/// Designed to eliminate visual disharmony (no overlapping badges) and
/// transaction race conditions across all 100 mini-games in VOWL.
class QuestHintButton extends StatelessWidget {
  /// Whether the current question's hint has already been revealed.
  final bool used;

  /// Primary color token for the active hint state (defaults to amber).
  final Color primaryColor;

  /// Optional pedagogical hint text for the current quest.
  final String? hintText;

  /// Callback executed when tapping the hint action.
  final VoidCallback onTap;

  /// Optional sound service instance (defaults to dependency injection).
  final SoundService? soundService;

  /// Whether the hint action is currently interactive.
  final bool isHintEnabled;

  const QuestHintButton({
    super.key,
    required this.used,
    this.primaryColor = AppColors.amber500,
    this.hintText,
    required this.onTap,
    this.soundService,
    this.isHintEnabled = true,
  });

  SoundService? get _sound {
    if (soundService != null) return soundService!;
    try {
      return di.sl<SoundService>();
    } catch (_) {
      return null;
    }
  }

  void _showHintFeedback(BuildContext context) {
    try {
      _sound?.playHint();
    } catch (_) {}

    if (hintText != null && hintText!.trim().isNotEmpty) {
      final isDynamic = HintUtility.isGenericHint(hintText!);
      final displayText = isDynamic
          ? context.tr(
              'hint.pro_tip_generic',
              fallback: 'Look for context clues to help find the right answer.',
            )
          : hintText!.trim();

      try {
        di.sl<TtsService>().stop();
        di.sl<TtsService>().speak(
          isDynamic
              ? context.tr('hint.pro_tip_tts', fallback: 'Look for context clues.')
              : hintText!.trim(),
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
      // Free review for the current question without spending extra hints
      _showHintFeedback(context);
      onTap();
      return;
    }

    if (isPremium) {
      // Premium users have unlimited hints - no deduction
      _showHintFeedback(context);
      onTap();
      return;
    }

    if (hintCount > 0) {
      // 1. Dispatches single event to EconomyBloc, which handles 0ms optimistic deduction
      //    via AuthBloc, remote Firestore transaction via useHint, and rollback on failure.
      try {
        context.read<EconomyBloc>().add(const EconomyConsumeHintRequested());
      } catch (_) {}

      // 2. Audio, TTS, and CustomSnackBar pedagogical feedback
      _showHintFeedback(context);

      // 3. Trigger in-game quest callback
      onTap();
    } else {
      // 0 hints remaining: Prompt Rewarded Ad dialog
      GameDialogHelper.showHintAdDialog(
        context,
        onHintEarned: () {
          _showHintFeedback(context);
          onTap();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final hintCount = authState.user?.hintCount ?? 0;
        final isPremium = authState.user?.isPremium ?? false;
        final canUseHint = hintCount > 0 || isPremium;

        return Semantics(
          button: true,
          label: isPremium
              ? context.tr('hint.use_hint_premium_semantic', fallback: 'Use hint (Unlimited)')
              : (hintCount > 0
                  ? context.tr(
                      'hint.use_hint_semantic',
                      args: ['$hintCount'],
                      fallback: 'Use hint ($hintCount remaining)',
                    )
                  : context.tr('hint.watch_ad_semantic', fallback: 'Watch video to unlock a hint')),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: !isHintEnabled
                  ? null
                  : () => _handleTap(context, hintCount: hintCount, isPremium: isPremium),
              borderRadius: BorderRadius.circular(12.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36.h,
                padding: EdgeInsets.symmetric(
                  horizontal: isPremium ? 10.w : 8.w,
                ),
                decoration: BoxDecoration(
                  color: !isHintEnabled
                      ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03))
                      : (canUseHint
                          ? AppColors.amber500.withValues(alpha: isDark ? 0.16 : 0.10)
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03))),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: !isHintEnabled
                        ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))
                        : (canUseHint
                            ? AppColors.amber500.withValues(alpha: isDark ? 0.45 : 0.35)
                            : AppColors.amber500.withValues(alpha: isDark ? 0.35 : 0.25)),
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (isHintEnabled)
                      BoxShadow(
                        color: AppColors.amber500.withValues(alpha: isDark ? 0.20 : 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon State: Lightbulb for available hints, Video Camera for rewarded ad
                    Icon(
                      canUseHint ? Icons.lightbulb_rounded : Icons.videocam_rounded,
                      color: !isHintEnabled
                          ? (isDark ? AppColors.slate600 : AppColors.slate400)
                          : AppColors.amber500,
                      size: canUseHint ? 18.r : 17.r,
                    ),

                    // Counter Pill or Rewarded Ad Text (+1)
                    if (!isPremium && isHintEnabled) ...[
                      SizedBox(width: 4.w),
                      Text(
                        canUseHint ? '$hintCount' : '+1',
                        textScaler: const TextScaler.linear(1.0),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.amber500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
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
