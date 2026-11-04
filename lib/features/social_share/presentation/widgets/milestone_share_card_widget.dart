import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';

class MilestoneShareCardWidget extends StatelessWidget {
  final ShareCardData data;

  const MilestoneShareCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340.w,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19), // Solid luxury obsidian
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: App Icon & Brand Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.asset(
                  'assets/images/playstore/play_store.png',
                  width: 32.w,
                  height: 32.w,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 10.w),
              Image.asset(
                'assets/images/vowl_logo.webp',
                height: 22.h,
                fit: BoxFit.contain,
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // User Avatar & Name
          UserAvatar(photoUrl: data.userPhotoUrl, size: 68.r),
          SizedBox(height: 12.h),
          Text(
            data.userName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.indigo500,
            ),
          ),

          SizedBox(height: 20.h),

          // Metric Highlight Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFF070A12),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              children: [
                if (data.type == ShareCardType.arenaVictory) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.swords, size: 24.sp, color: const Color(0xFFF59E0B)),
                      SizedBox(width: 8.w),
                      Text(
                        'ARENA DUEL VICTORY',
                        style: TextStyle(
                          fontSize: 11.sp,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${data.myScore ?? 0} PTS',
                    style: TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'vs ${data.rivalName ?? 'Rival'} (${data.rivalScore ?? 0} pts)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate400,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '+50 Coins 🪙 • +5 XP ⚡ Won',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ] else if (data.type == ShareCardType.referral) ...[
                  Icon(LucideIcons.gift, size: 28.sp, color: const Color(0xFF8B5CF6)),
                  SizedBox(height: 6.h),
                  Text(
                    '+100 COINS & VIP ACCESS',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Join my English mastery circle on Vowl',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.slate400,
                    ),
                  ),
                ] else if (data.rank != null) ...[
                  Text(
                    'GLOBAL LEAGUE',
                    style: TextStyle(
                      fontSize: 10.sp,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate400,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '#${data.rank}',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.slate400,
                    ),
                  ),
                ] else if (data.streak != null) ...[
                  Text(
                    'STREAK RECORD',
                    style: TextStyle(
                      fontSize: 10.sp,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate400,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.flame, size: 28.sp, color: const Color(0xFFF59E0B)),
                      SizedBox(width: 6.w),
                      Text(
                        '${data.streak} DAYS',
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Footer: Code Action
          if (data.type == ShareCardType.arenaVictory) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.swords, size: 14.sp, color: const Color(0xFFF59E0B)),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'Rematch Code: ${data.roomCode ?? "VOWL"} (Enter in app)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (data.referralCode != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.indigo500.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.gift, size: 14.sp, color: AppColors.indigo500),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'Use code: ${data.referralCode} for +100 Coins & Free VIP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

