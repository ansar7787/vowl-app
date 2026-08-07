import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';

class StreakBoostersShop extends StatefulWidget {
  final UserEntity user;

  const StreakBoostersShop({super.key, required this.user});

  @override
  State<StreakBoostersShop> createState() => _StreakBoostersShopState();
}

class _StreakBoostersShopState extends State<StreakBoostersShop> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: AutoSizeText(
                context.tr(
                  'streak.boosters_title',
                  fallback: 'STREAK BOOSTERS',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                minFontSize: 12,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              label: context.tr(
                'home.coins_value_label',
                args: [user.coins.toString()],
                fallback: '${user.coins} coins',
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.circleDollarSign,
                        color: Colors.green,
                        size: 16.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${user.coins}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().shimmer(duration: 3.seconds, color: Colors.white24),
          ],
        ),
        SizedBox(height: 24.h),
        _buildShopItem(
          context,
          title: context.tr('streak.repair_title', fallback: 'STREAK REPAIR'),
          subtitle: context.tr(
            'streak.repair_subtitle',
            fallback: 'Melt the ice and restore your flame from yesterday.',
          ),
          icon: LucideIcons.flame,
          color: const Color(0xFFFF5F6D),
          cost: 200,
          currentCoins: user.coins,
          isDisabled: user.currentStreak > 0,
          onTap: user.currentStreak > 0
              ? null
              : () => _handlePurchase(
                  context,
                  name: context.tr(
                    'adventure.streak_repair',
                    fallback: 'Streak Repair',
                  ),
                  cost: 200,
                  currentCoins: user.coins,
                  action: () => context.read<ProgressionBloc>().add(
                    const ProgressionRepairStreakRequested(200),
                  ),
                ),
          onAdTap: user.currentStreak > 0
              ? null
              : () {
                  final adService = di.sl<AdService>();
                  adService.showRewardedAd(
                    context: context,
                    isPremium: user.isPremium,
                    onDismissed: () {},
                    onUserEarnedReward: (reward) {
                      // BUG FIX: this callback can fire many seconds after
                      // the user started watching the rewarded ad — long
                      // enough that they may have already navigated away
                      // from this screen. Using `context` past that point
                      // without checking it's still mounted risks calling
                      // `context.read` on a deactivated element and crashing.
                      if (!context.mounted) return;
                      context.read<ProgressionBloc>().add(
                        const ProgressionRepairStreakWithAdRequested(),
                      );
                      try {
                        Haptics.vibrate(HapticsType.success);
                      } catch (e) {
                        if (kDebugMode) {
                          debugPrint(
                            'StreakBoostersShop: haptics unavailable: $e',
                          );
                        }
                      }
                      CustomSnackBar.show(
                        context: context,
                        message: context.tr(
                          'adventure.streak_repaired',
                          fallback: 'Streak Repaired!',
                        ),
                        type: CustomSnackBarType.success,
                      );
                    },
                  );
                },
        ),
        SizedBox(height: 16.h),
        _buildShopItem(
          context,
          title: context
              .tr('adventure.streak_shield', fallback: 'Streak Shield')
              .toUpperCase(),
          subtitle: context.tr(
            'streak.shield_subtitle',
            fallback: 'A mystical barrier that prevents streak loss.',
          ),
          icon: LucideIcons.shieldCheck,
          color: const Color(0xFF38BDF8),
          cost: 150,
          count: user.streakFreezes,
          currentCoins: user.coins,
          onTap: () => _handlePurchase(
            context,
            name: context.tr(
              'adventure.streak_shield',
              fallback: 'Streak Shield',
            ),
            cost: 150,
            currentCoins: user.coins,
            action: () => context.read<ProgressionBloc>().add(
              const ProgressionPurchaseStreakFreezeRequested(150),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildShopItem(
          context,
          title: context
              .tr('adventure.double_xp', fallback: 'DOUBLE XP BOOST')
              .toUpperCase(),
          subtitle: context.tr(
            'streak.double_xp_subtitle',
            fallback: 'Double the wisdom, double the progress for 24h.',
          ),
          icon: LucideIcons.zap,
          color: const Color(0xFFFCD34D),
          cost: 300,
          isActive: user.isDoubleXPActive,
          activeUntil: user.doubleXPExpiry,
          currentCoins: user.coins,
          onTap: () => _handlePurchase(
            context,
            name: context.tr(
              'adventure.double_xp',
              fallback: 'Double XP Boost',
            ),
            cost: 300,
            currentCoins: user.coins,
            action: () => context.read<ProgressionBloc>().add(
              const ProgressionActivateDoubleXPRequested(300),
            ),
          ),
        ),
      ],
    );
  }

  void _handlePurchase(
    BuildContext context, {
    required String name,
    required int cost,
    required int currentCoins,
    required VoidCallback action,
  }) async {
    if (_isProcessing) return;

    if (currentCoins < cost) {
      try {
        Haptics.vibrate(HapticsType.error);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('StreakBoostersShop: haptics unavailable: $e');
        }
      }
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'streak.insufficient_coins',
          args: [cost.toString()],
          fallback: 'Insufficient Vowl Coins! Needed: $cost',
        ),
        type: CustomSnackBarType.error,
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      Haptics.vibrate(HapticsType.heavy);
    } catch (e) {
      if (kDebugMode) debugPrint('StreakBoostersShop: haptics unavailable: $e');
    }
    action();

    if (context.mounted) {
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'streak.item_activated',
          args: [name],
          fallback: '$name Activated!',
        ),
        type: CustomSnackBarType.success,
      );
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _isProcessing = false);
  }

  Widget _buildShopItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int cost,
    required int currentCoins,
    required VoidCallback? onTap,
    VoidCallback? onAdTap,
    int? count,
    bool isActive = false,
    bool isDisabled = false,
    DateTime? activeUntil,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canAfford = currentCoins >= cost;
    final locale = Localizations.localeOf(context).toString();

    final statusLabel = isDisabled
        ? context.tr('streak.status_not_needed', fallback: 'NOT NEEDED')
        : (isActive
              ? context.tr('streak.status_active', fallback: 'ACTIVE')
              : (canAfford
                    ? context.tr(
                        'streak.cost_label',
                        args: [cost.toString()],
                        fallback: '$cost coins',
                      )
                    : context.tr(
                        'streak.cant_afford_label',
                        args: [cost.toString()],
                        fallback: 'Need $cost coins',
                      )));

    return Semantics(
      button: !isDisabled && !isActive,
      enabled: !isDisabled,
      label: '$title, $subtitle, $statusLabel',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(24.r),
            child: ExcludeSemantics(
              child: Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.white.withValues(alpha: 0.05)
                        : (canAfford
                              ? color.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2)),
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (canAfford)
                      BoxShadow(
                        color: color.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    !isDisabled
                        ? Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(icon, color: color, size: 24.r),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                duration: 2.seconds,
                              )
                        : Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.grey, size: 24.r),
                          ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: AutoSizeText(
                                  title,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 10,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (count != null && count > 0) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'x$count',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isDisabled ? Colors.grey : color,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                              if (isActive || isDisabled) ...[
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isActive
                                                  ? const Color(0xFF10B981)
                                                  : Colors.grey)
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: AutoSizeText(
                                      isActive
                                          ? context.tr(
                                              'streak.status_active',
                                              fallback: 'ACTIVE',
                                            )
                                          : context.tr(
                                              'streak.status_not_needed',
                                              fallback: 'NOT NEEDED',
                                            ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w800,
                                        color: isActive
                                            ? const Color(0xFF10B981)
                                            : Colors.grey,
                                      ),
                                      maxLines: 1,
                                      minFontSize: 6,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          AutoSizeText(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDisabled
                                  ? Colors.grey.withValues(alpha: 0.5)
                                  : (isDark ? Colors.white54 : Colors.black54),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            minFontSize: 8,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isActive && activeUntil != null) ...[
                            SizedBox(height: 4.h),
                            AutoSizeText(
                              context.tr(
                                'streak.expires_label',
                                args: [
                                  DateFormat(
                                    'MMM d, h:mm a',
                                    locale,
                                  ).format(activeUntil),
                                ],
                                fallback:
                                    'Expires ${DateFormat('MMM d, h:mm a', locale).format(activeUntil)}',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              minFontSize: 6,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isDisabled && !isActive) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? color.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: canAfford
                                ? color.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.circleDollarSign,
                              color: canAfford ? color : Colors.red,
                              size: 14.r,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '$cost',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                                color: canAfford ? color : Colors.red,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (onAdTap != null && !isDisabled) ...[
                      SizedBox(width: 8.w),
                      Semantics(
                        button: true,
                        label: context.tr(
                          'streak.watch_ad_free',
                          fallback: 'Watch an ad to get this for free',
                        ),
                        child: InkWell(
                          onTap: onAdTap,
                          child: ExcludeSemantics(
                            child: ConstrainedBox(
                              // Visual pill is intentionally compact; this
                              // guarantees the 48dp minimum tap target for a
                              // real monetization action without resizing it.
                              constraints: BoxConstraints(
                                minWidth: 48.r,
                                minHeight: 48.r,
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.playCircle,
                                      color: Colors.amber,
                                      size: 12.r,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      context.tr(
                                        'streak.free_label',
                                        fallback: 'FREE',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.amber,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
