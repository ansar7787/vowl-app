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
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.crown, size: 16.sp, color: const Color(0xFFF59E0B)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '👑 You hold Rank #1 in the World! Keep learning to defend your crown.',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF78350F),
                ),
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

    final droppedRanks = (currentUser.previousRank != null && currentUser.previousRank! < myRank)
        ? myRank - currentUser.previousRank!
        : 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: droppedRanks > 0
            ? AppColors.rose500.withValues(alpha: isDark ? 0.12 : 0.08)
            : AppColors.indigo500.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: droppedRanks > 0
              ? AppColors.rose500.withValues(alpha: 0.3)
              : AppColors.indigo500.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            droppedRanks > 0 ? LucideIcons.alertTriangle : LucideIcons.zap,
            size: 16.sp,
            color: droppedRanks > 0 ? AppColors.rose500 : AppColors.indigo500,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  droppedRanks > 0
                      ? '⚠️ Passed by $droppedRanks player${droppedRanks > 1 ? "s" : ""} today!'
                      : '⚡ $xpDiff XP to pass $rivalName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Play a quick quest to take Rank #$rivalRank',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B)),
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
              backgroundColor: droppedRanks > 0 ? AppColors.rose500 : AppColors.indigo500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'Overtake',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

