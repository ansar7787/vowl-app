import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class LeaderboardOvertakeHud extends StatelessWidget {
  final List<UserEntity> allUsers;
  final UserEntity currentUser;
  final bool isWeekly;
  final VoidCallback onOvertakeTap;

  const LeaderboardOvertakeHud({
    super.key,
    required this.allUsers,
    required this.currentUser,
    this.isWeekly = true,
    required this.onOvertakeTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final myIndex = allUsers.indexWhere((u) => u.id == currentUser.id);
    if (myIndex == -1) return const SizedBox.shrink();

    final myRank = myIndex + 1;

    // If Rank 1
    if (myRank == 1) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.crown, size: 16.sp, color: const Color(0xFFF59E0B)),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '👑 League Leader · Rank #1',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF78350F),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Keep practicing daily to defend your world crown',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      color: isDark ? AppColors.slate300 : const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Rival directly ahead of current user
    final rivalAhead = allUsers[myIndex - 1];
    final rivalRank = myRank - 1;
    final myScore = isWeekly ? currentUser.currentWeeklyExp : currentUser.totalExp;
    final rivalScore = isWeekly ? rivalAhead.currentWeeklyExp : rivalAhead.totalExp;
    final xpDiff = (rivalScore - myScore).clamp(1, 999999);
    final rivalName = rivalAhead.safeDisplayName;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.indigo500.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.zap,
              size: 16.sp,
              color: AppColors.indigo500,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⚡ +$xpDiff XP to take Rank #$rivalRank',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Target: $rivalName · 1 quick quest will push you ahead',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.slate300 : (tokens?.textSecondary ?? const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () {
              if (di.sl.isRegistered<HapticService>()) {
                di.sl<HapticService>().light();
              }
              onOvertakeTap();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sprint Now',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(LucideIcons.arrowUpRight, size: 12.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

