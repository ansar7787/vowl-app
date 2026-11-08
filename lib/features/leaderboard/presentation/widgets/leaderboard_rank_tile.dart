import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/locale_service.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color06b6d4 = Color(0xFF06B6D4);
  static const Color color60a5fa = Color(0xFF60A5FA);
}

/// List row tile representing a single ranked user with badge styling and score breakdown.
class LeaderboardRankTile extends StatelessWidget {
  final UserEntity user;
  final int rank;
  final bool isMe;
  final bool isKids;
  final bool isWeekly;
  final VoidCallback? onTap;

  const LeaderboardRankTile({
    super.key,
    required this.user,
    required this.rank,
    required this.isMe,
    this.isKids = false,
    this.isWeekly = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final levelsCleared = isKids
        ? user.kidsTotalLevelsCompleted
        : user.totalLevelsCompleted;
    final score = isKids
        ? user.kidsTotalStars
        : (isWeekly ? user.currentWeeklyExp : user.totalExp);
    final scoreLabel = isKids
        ? '⭐'
        : (isWeekly
              ? context.tr('leaderboard.weekly_xp', fallback: 'Weekly XP')
              : context.tr('leaderboard.xp', fallback: 'XP'));
    final tierColor = rank <= 5
        ? AppColors.indigo500
        : rank <= 10
        ? AppColors.blue500
        : rank <= 25
        ? _LocalPalette.color06b6d4
        : (isDark ? AppColors.slate400 : AppColors.slate700);
    final displayName = user.getSafeDisplayName(
      fallback: context.tr('leaderboard.player', fallback: 'Player'),
    );

    return Semantics(
      // FIX (HIGH-5): Full rank information announced for screen readers.
      // Includes rank, name, XP, streak, levels, and self-identification.
      label:
          'Rank $rank: $displayName. '
          '$score $scoreLabel. '
          '${user.currentStreak}-day streak. '
          '$levelsCleared levels cleared.'
          '${isMe ? " ${context.tr('leaderboard.this_is_you', fallback: 'This is you!')}" : ""}',
      child: GlassTile(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18.r),
        // PERF: blur: 0 disables BackdropFilter in the scroll list.
        // With 50+ tiles, each BackdropFilter creates an offscreen render
        // target — catastrophic on low-end devices. The glass overlay
        // gradient still provides the frosted visual.
        blur: 0,
        showShadow: false,
        borderColor: isMe
            ? (isDark
                  ? AppColors.blue500.withValues(alpha: 0.6)
                  : AppColors.indigo500.withValues(alpha: 0.5))
            : (isMidnight
                  ? Colors.white.withValues(alpha: 0.12)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.slate100)),
        color: isMidnight
            ? AppColors.midnightSurface
            : (isDark ? const Color(0xFF131A29) : Colors.white),
        borderWidth: 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18.r),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.cardCompact,
                vertical: 12.h,
              ),
              child: Row(
                children: [
                  // Rank number & Change Indicator
                  SizedBox(
                    width: 32.w,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              color: isDark
                                  ? tierColor.withValues(alpha: 0.9)
                                  : tierColor.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (!isKids && isWeekly) ...[
                          SizedBox(height: 2.h),
                          _buildRankChangeIndicator(
                            user.previousRank ?? rank,
                            rank,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Avatar
                  UserAvatar(
                    photoUrl: user.photoUrl,
                    size: 36.r,
                    border: Border.all(
                      color: tierColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Name & XP row
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        MeshGradientBackground.getContrastColor(
                                          context,
                                        ),
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            if (user.isPremium)
                              Padding(
                                padding: EdgeInsets.only(left: 4.w),
                                child: Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.amber500,
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
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      context.tr(
                                        'leaderboard.you',
                                        fallback: 'You',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 8.5.sp,
                                        fontWeight: FontWeight.w900,
                                        color: _LocalPalette.color60a5fa,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                isKids
                                    ? '${user.kidsTotalStars} ⭐ · ${user.kidsTotalLevelsCompleted} Levels'
                                    : '$score $scoreLabel · ${user.currentStreak}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.slate400
                                      : AppColors.slate600,
                                ),
                                softWrap: true,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Icon(
                              isKids ? Icons.star_rounded : LucideIcons.flame,
                              size: 12.r,
                              color: isKids
                                  ? AppColors.amber500
                                  : IllustrationColors.warmOrange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Levels cleared / Stars badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: (isKids ? AppColors.amber500 : tierColor)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: (isKids ? AppColors.amber500 : tierColor)
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isKids
                            ? '${user.kidsCoins} ⭐'
                            : context.tr(
                                'leaderboard.lvs',
                                fallback: 'Lv. {0}',
                                args: [levelsCleared.toString()],
                              ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: isKids ? AppColors.amber500 : tierColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankChangeIndicator(int previousRank, int currentRank) {
    final diff = previousRank - currentRank;
    if (diff > 0) {
      // Improved rank (e.g. from 10 to 5)
      return SizedBox(
        height: 12.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_upward_rounded,
              color: AppColors.emerald500,
              size: 10.r,
            ),
            Text(
              '$diff',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.emerald500,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    } else if (diff < 0) {
      // Dropped rank (e.g. from 5 to 10)
      return SizedBox(
        height: 12.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_downward_rounded,
              color: AppColors.red500,
              size: 10.r,
            ),
            Text(
              '${diff.abs()}',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.red500,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    } else {
      // No change
      return SizedBox(
        height: 12.h,
        child: Center(
          child: Container(
            width: 6.w,
            height: 2.h,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),
      );
    }
  }
}
