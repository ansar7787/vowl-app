import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/premium/presentation/pages/premium_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Unified monetization gate for ALL ML Kit features.
///
/// Generalizes the pattern from [TranslationMonetizationController] into a
/// reusable controller that any ML feature can use. The dialog presents
/// the same premium-quality glassmorphic UI with:
///   - A "Get Premium" path (navigates to PremiumScreen)
///   - A "Watch Ad" path (shows Rewarded Ad, then calls [onSuccess])
///
/// Usage:
/// ```dart
/// MlMonetizationController.attemptFeature(
///   context,
///   featureIcon: Icons.smart_toy_rounded,
///   featureTitle: 'AI Smart Reply',
///   featureSubtitle: 'Get AI-powered conversation suggestions',
///   adButtonLabel: 'Watch Ad (1 Suggestion)',
///   onSuccess: () => _showSmartReplies(),
/// );
/// ```
class MlMonetizationController {
  /// Attempts to use an ML feature, gating behind ads for free users.
  ///
  /// [onSuccess] is called if the user is Premium, or if they successfully
  /// watch a rewarded ad.
  static Future<void> attemptFeature(
    BuildContext context, {
    required VoidCallback onSuccess,
    required IconData featureIcon,
    required String featureTitle,
    required String featureSubtitle,
    required String adButtonLabel,
    bool isKidsZone = false,
  }) async {
    final authState = context.read<AuthBloc>().state;
    final isPremium = authState.user?.isPremium ?? false;

    // Premium users bypass all gates.
    if (isPremium) {
      onSuccess();
      return;
    }

    // Free users see the upsell dialog.
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MlFeatureGateDialog(
        featureIcon: featureIcon,
        featureTitle: featureTitle,
        featureSubtitle: featureSubtitle,
        adButtonLabel: adButtonLabel,
        isKidsZone: isKidsZone,
        onSuccess: onSuccess,
      ),
    );
  }
}

class _MlFeatureGateDialog extends StatelessWidget {
  final IconData featureIcon;
  final String featureTitle;
  final String featureSubtitle;
  final String adButtonLabel;
  final bool isKidsZone;
  final VoidCallback onSuccess;

  const _MlFeatureGateDialog({
    required this.featureIcon,
    required this.featureTitle,
    required this.featureSubtitle,
    required this.adButtonLabel,
    required this.isKidsZone,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ─────────────────────────────────────────
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 24.h),

              // ── Feature icon ────────────────────────────────────────
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(featureIcon, color: Colors.white, size: 32.r),
              ),
              SizedBox(height: 20.h),

              // ── Title ───────────────────────────────────────────────
              Text(
                featureTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                featureSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              SizedBox(height: 28.h),

              // ── Premium button ──────────────────────────────────────
              ScaleButton(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PremiumScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr(
                          'translation.get_premium_button',
                          fallback: 'Get Vowl Premium',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // ── Watch Ad button ─────────────────────────────────────
              ScaleButton(
                onTap: () {
                  Navigator.pop(context);
                  di.sl<AdService>().showRewardedAd(
                    context: context,
                    isPremium: false,
                    childSafe: isKidsZone,
                    onUserEarnedReward: (_) => onSuccess(),
                    onDismissed: () {},
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        adButtonLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
