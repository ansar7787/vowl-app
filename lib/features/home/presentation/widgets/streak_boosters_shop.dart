import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class StreakBoostersShop extends StatefulWidget {
  final UserEntity user;

  const StreakBoostersShop({
    super.key,
    required this.user,
  });

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
            Text(
              'STREAK BOOSTERS',
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.circleDollarSign,
                    color: Colors.green,
                    size: 16.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${user.coins}',
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ).animate().shimmer(duration: 3.seconds, color: Colors.white24),
          ],
        ),
        SizedBox(height: 24.h),
        _buildShopItem(
          context,
          title: 'STREAK REPAIR',
          subtitle: 'Melt the ice and restore your flame from yesterday.',
          icon: LucideIcons.flame,
          color: const Color(0xFFFF5F6D),
          cost: 200,
          currentCoins: user.coins,
          isDisabled: user.currentStreak > 0,
          onTap: user.currentStreak > 0
              ? null
              : () => _handlePurchase(
                    context,
                    name: 'Streak Repair',
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
                    isPremium: user.isPremium,
                    onDismissed: () {},
                    onUserEarnedReward: (reward) {
                      context.read<ProgressionBloc>().add(
                            const ProgressionRepairStreakWithAdRequested(),
                          );
                      try {
                        Haptics.vibrate(HapticsType.success);
                      } catch (_) {}
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("STREAK REPAIRED! 🔥"),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                  );
                },
        ),
        SizedBox(height: 16.h),
        _buildShopItem(
          context,
          title: 'STREAK SHIELD',
          subtitle: 'A mystical barrier that prevents streak loss.',
          icon: LucideIcons.shieldCheck,
          color: const Color(0xFF38BDF8),
          cost: 150,
          count: user.streakFreezes,
          currentCoins: user.coins,
          onTap: () => _handlePurchase(
            context,
            name: 'Streak Shield',
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
          title: 'DOUBLE XP BOOST',
          subtitle: 'Double the wisdom, double the progress for 24h.',
          icon: LucideIcons.zap,
          color: const Color(0xFFFCD34D),
          cost: 300,
          isActive: user.isDoubleXPActive,
          activeUntil: user.doubleXPExpiry,
          currentCoins: user.coins,
          onTap: () => _handlePurchase(
            context,
            name: 'Double XP',
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
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20.r,
              ),
              SizedBox(width: 12.w),
              Text(
                "Insufficient Vowl Coins! Needed: $cost",
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      Haptics.vibrate(HapticsType.heavy);
    } catch (_) {}
    action();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4.r),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: Colors.white, size: 16.r),
            ),
            SizedBox(width: 12.w),
            Text(
              "$name Activated!",
              style: TextStyle(fontFamily: 'Outfit', 
                fontWeight: FontWeight.w900,
                fontSize: 12.sp,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: EdgeInsets.all(20.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isDisabled
                    ? Colors.white.withValues(alpha: 0.05)
                    : (canAfford ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2)),
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
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 2.seconds,
                        )
                    : Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
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
                            child: Text(
                              title,
                              style: TextStyle(fontFamily: 'Outfit', 
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (count != null && count > 0) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'x$count',
                                style: TextStyle(fontFamily: 'Outfit', 
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDisabled ? Colors.grey : color,
                                ),
                              ),
                            ),
                          ],
                          if (isActive || isDisabled) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: (isActive ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'NOT NEEDED',
                                style: TextStyle(fontFamily: 'Outfit', 
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isActive ? const Color(0xFF10B981) : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(fontFamily: 'Outfit', 
                          fontSize: 12.sp,
                          color: isDisabled ? Colors.grey.withValues(alpha: 0.5) : (isDark ? Colors.white54 : Colors.black54),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isActive && activeUntil != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          "Expires ${DateFormat('MMM d, h:mm a').format(activeUntil)}",
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontSize: 10.sp,
                            color: const Color(0xFF10B981).withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isDisabled && !isActive) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: canAfford ? color.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: canAfford ? color.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
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
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: canAfford ? color : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (onAdTap != null && !isDisabled) ...[
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: onAdTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.playCircle,
                            color: Colors.amber,
                            size: 12.r,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'FREE',
                            style: TextStyle(fontFamily: 'Outfit', 
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
