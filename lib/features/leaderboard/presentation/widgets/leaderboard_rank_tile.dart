import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/shimmer_image.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/locale_service.dart';

class LeaderboardRankTile extends StatelessWidget {
  final UserEntity user;
  final int rank;
  final bool isMe;

  const LeaderboardRankTile({
    super.key,
    required this.user,
    required this.rank,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelsCleared = user.totalLevelsCompleted;
    final tierColor = rank <= 10
        ? const Color(0xFF3B82F6)
        : const Color(0xFF94A3B8);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 12.r),
        borderRadius: BorderRadius.circular(18.r),
        borderColor: isMe
            ? const Color(0xFF2563EB).withValues(alpha: 0.7)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFCBD5E1)),
        color: isMe
            ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(
                      alpha: 0.95,
                    )), // Pure white bg for light mode
        borderWidth: isMe ? 1.5 : 1,
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36.w,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: isMe
                      ? (isDark ? Colors.white : const Color(0xFF2563EB))
                      : (isDark
                            ? tierColor.withValues(alpha: 0.8)
                            : const Color(
                                0xFF334155,
                              )), // High contrast slate for light mode
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 12.w),
            // Avatar
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tierColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: ShimmerImage(
                  imageUrl: user.photoUrl ?? '',
                  width: 40.r,
                  height: 40.r,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Name & XP
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (user.displayName ?? context.tr('leaderboard.player'))
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: MeshGradientBackground.getContrastColor(
                              context,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isPremium)
                        Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Icon(
                            Icons.verified_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 14.r,
                          ),
                        ),
                      if (isMe)
                        Padding(
                          padding: EdgeInsets.only(left: 6.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              context.tr('leaderboard.you'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF60A5FA),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${user.totalExp} XP · ${user.currentStreak}🔥',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white38
                          : Colors.black54, // Increased contrast for light mode
                    ),
                  ),
                ],
              ),
            ),
            // Levels cleared
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: tierColor.withValues(alpha: 0.15)),
              ),
              child: Text(
                context.tr('leaderboard.lvs', args: [levelsCleared.toString()]),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: tierColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
