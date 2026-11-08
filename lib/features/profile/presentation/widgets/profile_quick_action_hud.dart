import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/premium_store_bottom_sheet.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

/// Floating quick-action HUD strip positioned directly beneath the Hero Passport.
///
/// Features a balanced 4-pod layout:
/// 1. **Coins Pod**: Displays user coins; taps directly into the dedicated Coins Screen (`/coins-details`).
/// 2. **Keys / Premium Store Pod**: For standard users, displays keys and opens `KeyShopBottomSheet`;
///    for premium users, keys are hidden and replaced with `Icons.storefront_rounded` opening `PremiumStoreBottomSheet`.
/// 3. **Daily Streak Pod**: Displays active streak; taps into the Streak Screen (`/streak`).
/// 4. **VIP / Daily Reward**: 1-tap claim pill when available, or instant VIP status / upgrade navigation.
class ProfileQuickActionHud extends StatelessWidget {
  /// Authenticated user entity.
  final UserEntity user;

  /// Creates a [ProfileQuickActionHud] for [user].
  const ProfileQuickActionHud({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);
    final isVipReady = user.isVipGiftAvailable;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        children: [
          // 1. Coins Pod -> Navigates to Official Coins Screen
          Expanded(
            child: _buildHudPod(
              context: context,
              borderColor: borderColor,
              onTap: () {
                di.sl<HapticService>().selection();
                context.push(AppRouter.questCoinsRoute);
              },
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.emerald500,
              label: '${user.coins}',
              labelColor: Theme.of(context).colorScheme.onSurface,
              semanticsLabel: 'Coins: ${user.coins}',
            ),
          ),
          SizedBox(width: 6.w),

          // 2. Keys Pod (Standard) / Premium Store Pod (Premium)
          Expanded(
            child: user.isPremium
                ? _buildHudPod(
                    context: context,
                    borderColor: borderColor,
                    onTap: () {
                      di.sl<HapticService>().selection();
                      PremiumStoreBottomSheet.show(
                        context: context,
                        isKidsMode: false,
                      );
                    },
                    icon: Icons.storefront_rounded,
                    iconColor: AppColors.amber500,
                    label: context.tr('profile.store', fallback: 'Store'),
                    labelColor: AppColors.amber500,
                    semanticsLabel: context.tr(
                      'profile.premium_store',
                      fallback: 'Premium Store',
                    ),
                  )
                : _buildHudPod(
                    context: context,
                    borderColor: borderColor,
                    onTap: () {
                      di.sl<HapticService>().selection();
                      KeyShopBottomSheet.show(
                        context: context,
                        isKidsMode: false,
                      );
                    },
                    icon: Icons.key_rounded,
                    iconColor: AppColors.amber500,
                    label: '${user.keys}',
                    labelColor: AppColors.amber500,
                    semanticsLabel: 'Keys: ${user.keys}',
                  ),
          ),
          SizedBox(width: 6.w),

          // 3. Daily Streak Pod -> Navigates to Streak Screen
          Expanded(
            child: _buildHudPod(
              context: context,
              borderColor: borderColor,
              onTap: () {
                di.sl<HapticService>().selection();
                context.push(AppRouter.streakRoute);
              },
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.rose500,
              label: '${user.currentStreak}d',
              labelColor: Theme.of(context).colorScheme.onSurface,
              semanticsLabel: 'Streak: ${user.currentStreak} days',
            ),
          ),
          SizedBox(width: 6.w),

          // 4. VIP / Daily Gift Action Pill
          Expanded(
            child: _buildVipPod(
              context: context,
              borderColor: borderColor,
              isVipReady: isVipReady,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudPod({
    required BuildContext context,
    required Color borderColor,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required String semanticsLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final podBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark
              ? const Color(0xFF131A29)
              : Colors.black.withValues(alpha: 0.035));

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          height: 42.h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            color: podBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 16.r),
              SizedBox(width: 4.5.w),
              Flexible(
                child: AutoSizeText(
                  label,
                  maxLines: 1,
                  minFontSize: 9,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVipPod({
    required BuildContext context,
    required Color borderColor,
    required bool isVipReady,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final podBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark
              ? const Color(0xFF131A29)
              : Colors.black.withValues(alpha: 0.035));

    if (isVipReady) {
      final shouldAnimate = !VowlMotion.shouldReduceMotion(context);
      final containerWidget = Container(
        height: 42.h,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: AppColors.amber500,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.amber600, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, color: Colors.black, size: 14.r),
            SizedBox(width: 3.5.w),
            Flexible(
              child: AutoSizeText(
                '+100',
                maxLines: 1,
                minFontSize: 9,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );

      return Semantics(
        button: true,
        label: 'Claim Daily VIP Reward +100 Coins',
        child: ScaleButton(
          onTap: () {
            di.sl<HapticService>().success();
            if (di.sl.isRegistered<SoundService>()) {
              di.sl<SoundService>().playCoinTally(count: 6);
            }
            context.read<EconomyBloc>().add(
              const EconomyClaimVipGiftRequested(),
            );
            CustomSnackBar.show(
              context: context,
              message: context.tr(
                'profile.vip_gift_claimed',
                fallback: 'Claimed +100 VIP bonus coins!',
              ),
              type: CustomSnackBarType.success,
            );
          },
          child: shouldAnimate
              ? containerWidget
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.03, 1.03),
                      duration: 800.ms,
                    )
              : containerWidget,
        ),
      );
    }

    return Semantics(
      button: true,
      label: user.isPremium ? 'VIP Active' : 'Upgrade to VIP',
      child: ScaleButton(
        onTap: () {
          if (!user.isPremium) {
            di.sl<HapticService>().selection();
            context.push(AppRouter.premiumRoute);
          } else {
            di.sl<HapticService>().light();
            CustomSnackBar.show(
              context: context,
              message: context.tr(
                'profile.vip_gift_already_claimed',
                fallback: 'Daily VIP reward claimed! Come back tomorrow.',
              ),
              type: CustomSnackBarType.info,
            );
          }
        },
        child: Container(
          height: 42.h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            color: podBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                user.isPremium
                    ? Icons.verified_rounded
                    : Icons.workspace_premium_rounded,
                color: user.isPremium
                    ? AppColors.amber500
                    : AppColors.indigo500,
                size: 15.r,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: AutoSizeText(
                  user.isPremium
                      ? 'VIP'
                      : context.tr('profile.upgrade_short', fallback: 'VIP'),
                  maxLines: 1,
                  minFontSize: 9,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: user.isPremium
                        ? AppColors.amber500
                        : AppColors.indigo500,
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
