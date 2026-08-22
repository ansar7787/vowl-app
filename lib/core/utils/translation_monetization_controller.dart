import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/premium/presentation/pages/premium_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/premium_upsell_content.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Manages the monetization flow for ML Kit Translations.
///
/// Intercepts a user's request to translate text (hint, explanation, etc.).
/// - If the user is Premium: Translates instantly for free.
/// - If the user is Free: Shows an upsell dialog to watch a Rewarded Ad or upgrade.
///   - On Ad Success: Translates the text.
class TranslationMonetizationController {
  /// Attempts to perform a translation action.
  ///
  /// [onSuccess] is called if the user is Premium, or if they successfully watch an ad.
  static Future<void> attemptTranslation(
    BuildContext context, {
    required VoidCallback onSuccess,
    bool isKidsZone = false,
  }) async {
    final authState = context.read<AuthBloc>().state;
    final isPremium = authState.user?.isPremium ?? false;

    if (isPremium) {
      onSuccess();
      return;
    }

    // Show Free User Dialog (Watch Ad or Upgrade)
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.9),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top right X button
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18.r,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    PremiumUpsellContent(
                      titleKey: 'translation.premium_upsell',
                      titleFallback: 'Instant Translation',
                      subtitleKey: 'translation.translate_cta',
                      subtitleFallback: 'Watch a quick ad to translate this text, or get Premium for unlimited access.',
                      adButtonTextKey: 'translation.watch_ad_button',
                      adButtonTextFallback: 'Watch Ad (1 Translation)',
                      onPremiumTap: () => Navigator.pop(ctx, 'premium'),
                      onAdTap: () => Navigator.pop(ctx, 'ad'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;

    if (result == 'premium') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
    } else if (result == 'ad') {
      // User chose to watch ad
      final adService = di.sl<AdService>();

      adService.showRewardedAd(
        context: context,
        isPremium: isPremium, // We know it's false here
        childSafe: isKidsZone,
        onUserEarnedReward: (RewardItem item) {
          // Ad watched successfully
          if (context.mounted) {
            onSuccess();
          }
        },
        onDismissed: () {
          // If they dismissed the ad early, onUserEarnedReward won't fire.
        },
      );
    }
  }
}
