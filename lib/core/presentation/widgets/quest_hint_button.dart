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

/// Tactile, modern hint action tile providing zero-latency (0ms)
/// hint deduction, rewarded ads for free users with 0 hints, and unlimited
/// hint access for premium users.
///
/// Features a badged squircle design (36x36dp) matching the game header HUD:
/// - Available hints: Golden lightbulb with top-right count badge.
/// - 0 hints (Free user): Video collection reel icon with bottom-right play badge (no cheap "+1" text).
/// - Revealed hint (Already used): Subtle, muted psychology icon (free re-review, no deduction).
/// - Premium user: Golden lightbulb without badges (unlimited access).
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

  void _showHintFeedback(BuildContext context, {bool isReview = false}) {
    if (!isReview) {
      try {
        _sound?.playHint();
      } catch (_) {}
    }

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
      // Free review for current question - no charge, no duplicate BLoC dispatch
      _showHintFeedback(context, isReview: true);
      return;
    }

    if (isPremium) {
      // Premium users have unlimited hints - no deduction
      _showHintFeedback(context, isReview: false);
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
      _showHintFeedback(context, isReview: false);

      // 3. Trigger in-game quest callback
      onTap();
    } else {
      // 0 hints remaining: Prompt Rewarded Ad dialog.
      // In-game rewarded ads unlock the hint directly for the active question
      // without depositing an unconsumed surplus hint into the persistent wallet.
      GameDialogHelper.showHintAdDialog(
        context,
        persistToAccount: false,
        onHintEarned: () {
          _showHintFeedback(context, isReview: false);
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

        // Visual State Resolution
        final bool isRevealed = used;
        final bool showAdState = !isRevealed && !canUseHint;
        final bool isInteractive = isHintEnabled;

        final Color tileColor;
        final Color borderColor;
        final Color iconColor;
        final IconData iconData;
        final List<BoxShadow> shadows;

        if (!isInteractive) {
          tileColor = isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03);
          borderColor = isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06);
          iconColor = isDark ? AppColors.slate600 : AppColors.slate400;
          iconData = Icons.lightbulb_rounded;
          shadows = const [];
        } else if (isRevealed) {
          // ── Revealed / Already Used State (Subtle muted tile, free re-review) ──
          tileColor = isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03);
          borderColor = isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.10);
          iconColor = isDark ? AppColors.slate300 : AppColors.slate700;
          iconData = Icons.psychology_outlined;
          shadows = const [];
        } else if (showAdState) {
          // ── 0 Hints Remaining: Rewarded Video Ad State (Classic Video Collection Reel Icon) ──
          tileColor = AppColors.amber500.withValues(alpha: isDark ? 0.14 : 0.09);
          borderColor = AppColors.amber500.withValues(alpha: isDark ? 0.38 : 0.28);
          iconColor = AppColors.amber500;
          iconData = Icons.video_collection_rounded;
          shadows = [
            BoxShadow(
              color: AppColors.amber500.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1.5),
            ),
          ];
        } else {
          // ── Active Hint Available ──
          tileColor = AppColors.amber500.withValues(alpha: isDark ? 0.16 : 0.10);
          borderColor = AppColors.amber500.withValues(alpha: isDark ? 0.45 : 0.35);
          iconColor = AppColors.amber500;
          iconData = Icons.lightbulb_rounded;
          shadows = [
            BoxShadow(
              color: AppColors.amber500.withValues(alpha: isDark ? 0.22 : 0.10),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ];
        }

        return Semantics(
          button: true,
          label: isRevealed
              ? context.tr('hint.review_hint_semantic', fallback: 'Review hint (Unlocked)')
              : (isPremium
                  ? context.tr('hint.use_hint_premium_semantic', fallback: 'Use hint (Unlimited)')
                  : (hintCount > 0
                      ? context.tr(
                          'hint.use_hint_semantic',
                          args: ['$hintCount'],
                          fallback: 'Use hint ($hintCount remaining)',
                        )
                      : context.tr('hint.watch_ad_semantic', fallback: 'Watch video to unlock a hint'))),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: !isHintEnabled
                  ? null
                  : () => _handleTap(context, hintCount: hintCount, isPremium: isPremium),
              borderRadius: BorderRadius.circular(12.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: borderColor,
                    width: 1.2,
                  ),
                  boxShadow: shadows,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Main Action Icon
                    Icon(
                      iconData,
                      color: iconColor,
                      size: isRevealed ? 20.r : (showAdState ? 19.r : 19.r),
                    ),

                    // Hint Count Badge (when hints available and not yet used on current quest)
                    if (isInteractive && !isRevealed && !isPremium && hintCount > 0)
                      Positioned(
                        top: -3.r,
                        right: -3.r,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AppColors.amber500,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF131B2B) : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 15.r,
                            minHeight: 15.r,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$hintCount',
                            textScaler: const TextScaler.linear(1.0),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
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
