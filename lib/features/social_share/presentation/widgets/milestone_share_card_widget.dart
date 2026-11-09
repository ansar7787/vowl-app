import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';

/// Production multi-theme milestone share card supporting dynamic Light and Dark modes.
///
/// Cleanly handles:
/// - 1v1 Arena Duel Invites (`arenaInvite`)
/// - 1v1 Arena Victories (`arenaVictory`)
/// - Ambassador & Referral codes (`referral`)
/// - Leaderboard Rank & Daily Streaks (`rank`, `streak`)
class MilestoneShareCardWidget extends StatelessWidget {
  final ShareCardData data;

  const MilestoneShareCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF0B0F19) : Colors.white;
    final metricBg = isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;
    final logoColor = isDark ? Colors.white : AppColors.indigo600;

    final String tagLabel;
    final IconData tagIcon;
    final Color tagColor;

    switch (data.type) {
      case ShareCardType.arenaInvite:
        tagLabel = '#1v1 DUEL';
        tagIcon = LucideIcons.swords;
        tagColor = AppColors.indigo500;
        break;
      case ShareCardType.arenaVictory:
        tagLabel = '#DUEL WINNER';
        tagIcon = LucideIcons.trophy;
        tagColor = AppColors.amber500;
        break;
      case ShareCardType.referral:
        tagLabel = '#AMBASSADOR';
        tagIcon = LucideIcons.gift;
        tagColor = AppColors.violet500;
        break;
      case ShareCardType.rank:
        tagLabel = '#LEAGUE RANK';
        tagIcon = LucideIcons.medal;
        tagColor = AppColors.amber500;
        break;
      case ShareCardType.streak:
        tagLabel = '#DAILY STREAK';
        tagIcon = LucideIcons.flame;
        tagColor = AppColors.rose500;
        break;
    }

    return Container(
      width: 340.w,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.indigo500.withValues(alpha: 0.25)
              : AppColors.indigo500.withValues(alpha: 0.20),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : AppColors.indigo500.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Header Row: Subtle Vowl Brand Watermark (Left) + Context Tag (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Subtle Brand Mark (Left) with Official Play Store App Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: Image.asset(
                      'assets/images/playstore/play_store.png',
                      width: 22.r,
                      height: 22.r,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'V',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Text(
                    'VOWL',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: logoColor,
                    ),
                  ),
                ],
              ),

              // Context Category Pill (Right)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: tagColor.withValues(alpha: 0.25),
                    width: 1.r,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tagIcon, size: 10.sp, color: tagColor),
                    SizedBox(width: 4.w),
                    Text(
                      tagLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: tagColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // 2. User Avatar & Display Name
          UserAvatar(photoUrl: data.userPhotoUrl, size: 64.r),
          SizedBox(height: 10.h),
          Text(
            data.userName,
            textAlign: TextAlign.center,
            maxLines: 2,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.indigo500,
            ),
          ),

          SizedBox(height: 18.h),

          // 3. Highlight Metric Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: metricBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                // Case A: 1v1 Arena Invite Challenge
                if (data.type == ShareCardType.arenaInvite) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.swords,
                          size: 16.sp,
                          color: AppColors.indigo500,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '1v1 DUEL CHALLENGE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.indigo950.withValues(alpha: 0.4)
                          : AppColors.indigo50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      data.roomCode ?? 'VOWL-DUEL',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: isDark ? Colors.white : AppColors.indigo600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 3.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.amber500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Stake 30🪙 • Winner Takes 50🪙 + 5 XP',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber500,
                      ),
                    ),
                  ),
                ]
                // Case B: 1v1 Arena Victory
                else if (data.type == ShareCardType.arenaVictory) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.trophy,
                        size: 20.sp,
                        color: AppColors.amber500,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'DUEL VICTORY',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.amber500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${data.myScore ?? 0} PTS',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'vs ${data.rivalName ?? 'Rival'} (${data.rivalScore ?? 0} pts)',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${data.payoutCoins ?? 50} Coins 🪙 + 5 XP ⚡ Won',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber500,
                      ),
                    ),
                  ),
                ]
                // Case C: Referral & Ambassador Program
                else if (data.type == ShareCardType.referral) ...[
                  Icon(
                    LucideIcons.gift,
                    size: 28.sp,
                    color: AppColors.violet500,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '+100 COINS & VIP ACCESS',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Learn English with me on Vowl',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      color: textSecondary,
                    ),
                  ),
                ]
                // Case D: Global Rank
                else if (data.rank != null) ...[
                  Text(
                    'GLOBAL LEAGUE',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '#${data.rank}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.amber500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      color: textSecondary,
                    ),
                  ),
                ]
                // Case E: Daily Streak
                else if (data.streak != null) ...[
                  Text(
                    'STREAK RECORD',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.flame,
                        size: 28.sp,
                        color: AppColors.amber500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${data.streak} DAYS',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // 4. Footer Code Section (Clean 2-tier coupon layout)
          if (data.type == ShareCardType.arenaInvite) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.25),
                  width: 1.r,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.swords,
                        size: 14.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'DUEL CODE: ${data.roomCode ?? "VOWL"}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white : AppColors.indigo600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Enter code in Vowl app to accept duel',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (data.type == ShareCardType.arenaVictory) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.25),
                  width: 1.r,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.zap,
                        size: 14.sp,
                        color: AppColors.amber500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '1v1 DUEL WINNER',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.amber500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Play 1v1 English duels on Vowl',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (data.referralCode != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.violet500.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.violet500.withValues(alpha: 0.25),
                  width: 1.r,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.gift,
                        size: 14.sp,
                        color: AppColors.violet500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'CODE: ${data.referralCode}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Enter code in Vowl app for 100 free coins',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.20),
                  width: 1.r,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        size: 14.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'JOIN THE LEAGUE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white : AppColors.indigo600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Learn English vocabulary & grammar on Vowl',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
