import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final myIndex = allUsers.indexWhere((u) => u.id == currentUser.id);
    if (myIndex == -1) return const SizedBox.shrink();

    final myRank = myIndex + 1;
    final contrastColor = Theme.of(context).colorScheme.onSurface;
    final secondaryTextColor = isDark ? Colors.white60 : AppColors.slate500;

    // -------------------------------------------------------------------------
    // Case 1: Current User is Rank 1 (Championship Defense Card)
    // -------------------------------------------------------------------------
    if (myRank == 1) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: 6.h,
        ),
        child: GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          borderRadius: BorderRadius.circular(24.r),
          blur: 0,
          borderColor: isMidnight
              ? Colors.white.withValues(alpha: 0.12)
              : (isDark
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.35)),
          color: isMidnight
              ? AppColors.midnightSurface
              : (isDark ? const Color(0xFF131A29) : Colors.white),
          borderWidth: 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Rank 1 Gold Emblem
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '#1',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  UserAvatar(
                    photoUrl: currentUser.photoUrl,
                    size: 36.r,
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWeekly ? 'LEAGUE LEADER' : 'ALL-TIME LEADER',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFF59E0B),
                            letterSpacing: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentUser.safeDisplayName,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: contrastColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.trophy,
                          size: 12.sp,
                          color: const Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Defending',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Full Gold Progress Bar (Solid championship amber)
              Container(
                height: 6.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      isWeekly
                          ? 'Rank 1 · Defending Champion'
                          : 'Rank 1 · All-Time Legend',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : AppColors.slate700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Keep practicing daily 🔥',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // Case 2: Overtake Target Card (Mirroring our rank card structure)
    // -------------------------------------------------------------------------
    final rivalAhead = allUsers[myIndex - 1];
    final rivalRank = myRank - 1;
    final myScore = isWeekly
        ? currentUser.currentWeeklyExp
        : currentUser.totalExp;
    final rivalScore = isWeekly
        ? rivalAhead.currentWeeklyExp
        : rivalAhead.totalExp;
    final xpDiff = (rivalScore - myScore).clamp(1, 999999);
    final rivalName = rivalAhead.safeDisplayName;

    // Relative progress toward rival's score
    final progress = rivalScore > 0
        ? (myScore / rivalScore).clamp(0.08, 0.98)
        : 0.5;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: 6.h,
      ),
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        borderRadius: BorderRadius.circular(24.r),
        blur: 0,
        borderColor: isMidnight
            ? Colors.white.withValues(alpha: 0.12)
            : (isDark
                  ? AppColors.indigo500.withValues(alpha: 0.3)
                  : AppColors.indigo500.withValues(alpha: 0.2)),
        color: isMidnight
            ? AppColors.midnightSurface
            : (isDark ? const Color(0xFF131A29) : Colors.white),
        borderWidth: 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Target Rank Circle
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.indigo500, AppColors.blue500],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '#$rivalRank',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Rival Avatar
                UserAvatar(
                  photoUrl: rivalAhead.photoUrl,
                  size: 36.r,
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                SizedBox(width: 8.w),
                // Target Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isWeekly
                              ? 'NEXT TARGET · OVERTAKE'
                              : 'NEXT TARGET · GLOBAL RANK',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: secondaryTextColor,
                            letterSpacing: 1.3,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          rivalName,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: contrastColor,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // High-Energy Sprint CTA Pill
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (di.sl.isRegistered<HapticService>()) {
                        di.sl<HapticService>().light();
                      }
                      onOvertakeTap();
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.indigo500, Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sprint',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            LucideIcons.zap,
                            size: 12.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Progress Bar (You vs Target)
            Stack(
              children: [
                Container(
                  height: 6.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: AppColors.indigo500,
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '⚡ +$xpDiff XP to take Rank #$rivalRank',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.slate700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    xpDiff <= 60
                        ? '1 quest to pass'
                        : (xpDiff <= 150
                              ? 'A few quests to pass'
                              : 'Keep climbing 🔥'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
