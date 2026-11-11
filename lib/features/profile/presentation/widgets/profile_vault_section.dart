import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vowl/core/constants/app_urls.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/premium_store_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_feature_card.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color4f46e5 = Color(0xFF4F46E5);
}

/// Vault & Rewards section containing Ambassador referral tools, Key/Coin store,
/// and Premium membership perks.
class ProfileVaultSection extends StatelessWidget {
  /// Authenticated user entity.
  final UserEntity user;

  /// Creates a [ProfileVaultSection] for [user].
  const ProfileVaultSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    final code = user.referralCode ?? 'VOWL-HERO';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ambassador / Invite Friends Card
          GlassTile(
            borderRadius: BorderRadius.circular(24.r),
            padding: EdgeInsets.all(AppSpacing.card),
            borderColor: borderColor,
            borderWidth: 1.0,
            blur: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleButton(
                  onTap: () {
                    di.sl<HapticService>().selection();
                    context.push(AppRouter.referralRoute);
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.indigo500, AppColors.violet500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.indigo500.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.card_giftcard_rounded,
                          color: Colors.white,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'profile.ambassador_program',
                                fallback: 'INVITE & EARN',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.indigo400
                                    : AppColors.indigo600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              context.tr(
                                'profile.ambassador_title',
                                fallback: 'Invite Friends, Earn VIP',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hub',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.slate300
                                    : AppColors.slate700,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10.r,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Mutual Perk Callout Pill
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(
                      alpha: isDark ? 0.12 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14.r,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'You both get +100 '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 2.w,
                                    ),
                                    child: Icon(
                                      LucideIcons.coins,
                                      size: 13.r,
                                      color: AppColors.amber500,
                                    ),
                                  ),
                                ),
                                const TextSpan(text: ' & 1 Day VIP'),
                              ],
                            ),
                            maxLines: 1,
                            semanticsLabel:
                                'You both get plus 100 coins and 1 Day VIP',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.indigo950,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Dedicated Full-Width Invite Code Box (Zero Ellipsis Guaranteed)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.slate200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'profile.your_referral_code',
                                fallback: 'YOUR INVITE CODE',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              code,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: AppColors.indigo500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ScaleButton(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          di.sl<HapticService>().success();
                          CustomSnackBar.show(
                            context: context,
                            message: context.tr(
                              'profile.code_copied',
                              fallback: 'Invite code copied to clipboard!',
                            ),
                            type: CustomSnackBarType.success,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.indigo500.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                color: AppColors.indigo500,
                                size: 14.r,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                context.tr('profile.copy', fallback: 'Copy'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.indigo500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Bottom Action Bar: Share Link & Monthly Cup Standing
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ScaleButton(
                        onTap: () async {
                          di.sl<HapticService>().selection();
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Practice English with me on Vowl! Use my invite code $code to unlock 100 Bonus Coins and 1 Day of VIP access:\n${AppUrls.invite(code)}',
                              subject: 'Join me on Vowl!',
                            ),
                          );
                        },
                        child: Container(
                          height: 38.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.indigo500,
                                AppColors.violet500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.indigo500.withValues(
                                  alpha: 0.30,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.share_rounded,
                                  color: Colors.white,
                                  size: 14.r,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  context.tr(
                                    'common.share',
                                    fallback: 'Share Link',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      flex: 4,
                      child: ScaleButton(
                        onTap: () {
                          di.sl<HapticService>().selection();
                          context.push(AppRouter.referralRoute, extra: 1);
                        },
                        child: Container(
                          height: 38.h,
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.slate100,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.slate200,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  color: AppColors.amber500,
                                  size: 15.r,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  user.totalReferralsCount > 0
                                      ? '${user.totalReferralsCount} Joined • Cup'
                                      : 'Monthly Cup',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.slate800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 2. Coin Store / Golden Keys Banner
          if (user.isPremium)
            ProfileFeatureCard(
              iconContent: Icon(
                Icons.monetization_on_rounded,
                color: Colors.white,
                size: 24.r,
              ),
              color: AppColors.amber500,
              shadowColor: AppColors.amber600,
              title: context.tr('store.title', fallback: 'Coin Store'),
              subtitle: context.tr(
                'store.subtitle',
                fallback: 'Get coin packs to power up your progress!',
              ),
              onTap: () {
                di.sl<HapticService>().selection();
                PremiumStoreBottomSheet.show(context: context);
              },
            )
          else
            ProfileFeatureCard(
              iconContent: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.key_rounded, color: Colors.white, size: 20.r),
                  SizedBox(width: 8.w),
                  Text(
                    '${user.keys}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              color: Colors.amber,
              shadowColor: Colors.amber.withValues(alpha: 0.9),
              title: context.tr(
                'profile.golden_keys_title',
                fallback: 'Golden Keys',
              ),
              subtitle: context.tr(
                'profile.golden_keys_subtitle',
                fallback: 'Get more keys to unlock gates instantly!',
              ),
              onTap: () {
                di.sl<HapticService>().selection();
                KeyShopBottomSheet.show(context: context);
              },
            ),
          SizedBox(height: 16.h),

          // 3. Premium Active Perks or Upgrade Banner
          if (user.isPremium)
            ProfileFeatureCard(
              iconContent: const Icon(
                Icons.verified_rounded,
                color: Colors.white,
                size: 24,
              ),
              color: AppColors.emerald500,
              shadowColor: const Color(0xFF059669),
              title: context.tr(
                'profile.premium_active',
                fallback: 'Premium Active',
              ),
              subtitle: context.tr(
                'profile.premium_active_subtitle',
                fallback:
                    'Unlimited lives, double streak protection & VIP perks.',
              ),
              onTap: () {
                di.sl<HapticService>().selection();
                context.push(AppRouter.premiumRoute);
              },
            )
          else
            ProfileFeatureCard(
              iconContent: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 24,
              ),
              color: AppColors.indigo500,
              shadowColor: _LocalPalette.color4f46e5,
              title: context.tr(
                'profile.upgrade_to_premium',
                fallback: 'UPGRADE TO PREMIUM',
              ),
              subtitle: context.tr(
                'profile.upgrade_to_premium_subtitle',
                fallback:
                    'Unlock all features, remove limits & enjoy VIP gifts.',
              ),
              onTap: () {
                di.sl<HapticService>().selection();
                context.push(AppRouter.premiumRoute);
              },
            ),
        ],
      ),
    );
  }
}
