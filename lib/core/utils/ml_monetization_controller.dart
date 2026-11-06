import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/premium/presentation/pages/premium_screen.dart';

/// Unified monetization gate for ALL ML Kit features.
///
/// Supports both hard-gated features and high-retention Freemium Daily Quotas
/// (e.g. 3 free daily camera scans per feature). Free users can experience the
/// full value before hitting a monetization gate, while Premium users enjoy
/// 100% unlimited daily usage with zero ads.
class MlMonetizationController {
  /// Attempts to use an ML feature, gating behind ads for free users.
  ///
  /// When [featureKey] and [freeDailyLimit] are provided, grants [freeDailyLimit]
  /// free uses per calendar day (resetting at midnight). Once the quota is
  /// exhausted (attempt 4+), displays the monetization gate offering Rewarded
  /// Ads (+1 bonus scan) or Vowl Premium.
  ///
  /// Premium users always bypass immediately with zero ads.
  static Future<void> attemptFeature(
    BuildContext context, {
    required VoidCallback onSuccess,
    required IconData featureIcon,
    required String featureTitle,
    required String featureSubtitle,
    required String adButtonLabel,
    String? featureKey,
    int? freeDailyLimit,
    bool isKidsZone = false,
  }) async {
    final authState = context.read<AuthBloc>().state;
    final isPremium = authState.user?.isPremium ?? false;

    // 1. Premium users bypass all gates unconditionally
    if (isPremium) {
      onSuccess();
      return;
    }

    // 2. Check Daily Free Quota if configured
    if (featureKey != null && freeDailyLimit != null && freeDailyLimit > 0) {
      try {
        final prefs = di.sl.isRegistered<SharedPreferences>()
            ? di.sl<SharedPreferences>()
            : await SharedPreferences.getInstance();

        final today = DateTime.now().toIso8601String().substring(0, 10);
        final dateKey = 'ml_quota_date_$featureKey';
        final countKey = 'ml_quota_count_$featureKey';

        final lastDate = prefs.getString(dateKey) ?? '';
        int currentCount = prefs.getInt(countKey) ?? 0;

        // Reset on date change
        if (lastDate != today) {
          currentCount = 0;
          await prefs.setString(dateKey, today);
          await prefs.setInt(countKey, 0);
        }

        // Within daily free quota: consume 1 free scan and execute
        if (currentCount < freeDailyLimit) {
          await prefs.setInt(countKey, currentCount + 1);
          onSuccess();
          return;
        }
      } catch (_) {
        // Fail-open on storage failure to ensure uninterrupted learning
        onSuccess();
        return;
      }
    }

    // 3. Free quota exhausted or hard-gated feature — show upsell dialog
    if (!context.mounted) return;

    final isQuotaExhausted = featureKey != null && freeDailyLimit != null;
    final title = isQuotaExhausted
        ? context.tr(
            'translation.daily_quota_title',
            args: [freeDailyLimit.toString(), freeDailyLimit.toString()],
            fallback: 'DAILY SCANS USED ($freeDailyLimit/$freeDailyLimit)',
          )
        : featureTitle;
    final subtitle = isQuotaExhausted
        ? context.tr(
            'translation.daily_quota_desc',
            args: [freeDailyLimit.toString()],
            fallback: 'You’ve used your $freeDailyLimit free daily scans! Watch 1 quick ad for a bonus scan, or get Unlimited Scans with Vowl Premium.',
          )
        : featureSubtitle;

    final result = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MlFeatureGateDialog(
        featureIcon: featureIcon,
        featureTitle: title,
        featureSubtitle: subtitle,
        adButtonLabel: adButtonLabel,
        isKidsZone: isKidsZone,
        onSuccess: onSuccess,
      ),
    );

    if (!context.mounted) return;

    if (result == 'premium') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      if (!context.mounted) return;
      final updatedIsPremium =
          context.read<AuthBloc>().state.user?.isPremium ?? false;
      if (updatedIsPremium) {
        onSuccess();
      }
    } else if (result == 'ad') {
      di.sl<AdService>().showRewardedAd(
        context: context,
        isPremium: false,
        childSafe: isKidsZone,
        onUserEarnedReward: (_) => onSuccess(),
        onDismissed: () {},
      );
    }
  }

  /// Returns the number of remaining free daily uses for [featureKey] today.
  static Future<int> getRemainingDailyScans(
    String featureKey, {
    int freeDailyLimit = 3,
  }) async {
    try {
      final prefs = di.sl.isRegistered<SharedPreferences>()
          ? di.sl<SharedPreferences>()
          : await SharedPreferences.getInstance();

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final dateKey = 'ml_quota_date_$featureKey';
      final countKey = 'ml_quota_count_$featureKey';

      final lastDate = prefs.getString(dateKey) ?? '';
      final currentCount = (lastDate == today) ? (prefs.getInt(countKey) ?? 0) : 0;

      final remaining = freeDailyLimit - currentCount;
      return remaining > 0 ? remaining : 0;
    } catch (_) {
      return freeDailyLimit;
    }
  }

  /// Returns the number of used daily scans for [featureKey] today.
  static Future<int> getUsedDailyScans(String featureKey) async {
    try {
      final prefs = di.sl.isRegistered<SharedPreferences>()
          ? di.sl<SharedPreferences>()
          : await SharedPreferences.getInstance();

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final dateKey = 'ml_quota_date_$featureKey';
      final countKey = 'ml_quota_count_$featureKey';

      final lastDate = prefs.getString(dateKey) ?? '';
      return (lastDate == today) ? (prefs.getInt(countKey) ?? 0) : 0;
    } catch (_) {
      return 0;
    }
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final systemBottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final safeBottom =
        (systemBottomPadding > 0 ? systemBottomPadding : 24.h) +
        bottomInset +
        12.h;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, safeBottom),
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
          child: SingleChildScrollView(
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
                    colors: [AppColors.indigo500, AppColors.violet500],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.3),
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
                  Navigator.pop(context, 'premium');
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.indigo500, AppColors.violet500],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo500.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          context.tr(
                            'translation.get_premium_button',
                            fallback: 'Get Vowl Premium',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w900,
                            fontSize: 16.sp,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
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
                  Navigator.pop(context, 'ad');
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
                      Icon(
                        Icons.play_circle_outline_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          adButtonLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
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
    ),
  );
  }
}
