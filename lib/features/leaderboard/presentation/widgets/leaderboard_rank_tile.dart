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
    final displayName = user.displayName ?? context.tr('leaderboard.player', fallback: 'Player');

    return Semantics(
      // FIX (HIGH-5): Full rank information announced for screen readers.
      // Includes rank, name, XP, streak, levels, and self-identification.
      label:
          'Rank $rank: $displayName. '
          '${user.totalExp} XP. '
          '${user.currentStreak}-day streak. '
          '$levelsCleared levels cleared.'
          '${isMe ? " ${context.tr('leaderboard.this_is_you', fallback: 'This is you!')}" : ""}',
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        child: GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 12.r),
          borderRadius: BorderRadius.circular(18.r),
          borderColor: isMe
              ? (isDark
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                    : const Color(0xFF2563EB).withValues(alpha: 0.3))
              : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFCBD5E1).withValues(alpha: 0.6)),
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(
                  alpha: 0.75,
                ), // More translucent for frosty effect
          borderWidth: isMe ? 1.5 : 1,
          child: Row(
            children: [
              // Rank number
              SizedBox(
                width: 44.w,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: isDark
                        ? tierColor.withValues(alpha: 0.9)
                        : tierColor.withValues(alpha: 0.8),
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
              // Name & XP row
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName.toUpperCase(),
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
                            child: ExcludeSemantics(
                              // Already covered by the parent Semantics label.
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
                                  context.tr('leaderboard.you', fallback: 'You'),
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
                        color: isDark ? Colors.white38 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Levels cleared badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: tierColor.withValues(alpha: 0.15)),
                ),
                child: Text(
                  context.tr(
                    'leaderboard.lvs',
                    args: [levelsCleared.toString()],
                  ),
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
      ),
    );
  }
}
