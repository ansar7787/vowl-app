import 'package:intl/intl.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_theme.dart';
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
        ? 'Stars'
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
          '${isKids ? "$levelsCleared levels cleared." : "Level ${user.level}."}'
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
                        : AppTheme.borderLight)),
        color: isMidnight
            ? AppColors.midnightSurface
            : (isDark ? AppColors.midnightNavy : Colors.white),
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
                  // Rank number & Change Indicator side-by-side (adaptive width for Weekly vs Global/Kids)
                  SizedBox(
                    width: (!isKids && isWeekly) ? 50.w : 28.w,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: (!isKids && isWeekly)
                          ? Alignment.centerLeft
                          : Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '$rank',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: (!isKids && isWeekly) ? 19.sp : 21.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              color: isDark
                                  ? tierColor.withValues(alpha: 0.9)
                                  : tierColor.withValues(alpha: 0.8),
                            ),
                          ),
                          if (!isKids && isWeekly) ...[
                            SizedBox(width: 4.w),
                            _buildRankChangeIndicator(
                              user.previousRank ?? rank,
                              rank,
                            ),
                          ],
                        ],
                      ),
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
                                    ? '${user.kidsTotalLevelsCompleted} Levels · ${user.kidsCoins} Coins'
                                    : 'Lv. ${user.level} · ${user.currentStreak}d',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.slate400
                                      : AppColors.slate600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Icon(
                              isKids ? Icons.monetization_on_rounded : LucideIcons.flame,
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
                  // Primary Score / XP Badge
                  Container(
                    constraints: BoxConstraints(
                      minWidth: 52.w,
                      maxWidth: 90.w,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 5.h,
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
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isKids) ...[
                            Icon(
                              Icons.star_rounded,
                              size: 13.sp,
                              color: AppColors.amber500,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _formatScore(user.kidsTotalStars),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.amber500,
                              ),
                            ),
                          ] else ...[
                            Text(
                              '${_formatScore(score)} XP',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: tierColor,
                              ),
                            ),
                          ],
                        ],
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

  static String _formatScore(int value) {
    if (value >= 100000) {
      return NumberFormat.compact().format(value);
    }
    return NumberFormat('#,###').format(value);
  }

  Widget _buildRankChangeIndicator(int previousRank, int currentRank) {
    final diff = previousRank - currentRank;
    final bool improved = diff > 0;
    final bool dropped = diff < 0;
    final Color color;
    final Color bgColor;

    if (improved) {
      color = AppColors.emerald500;
      bgColor = AppColors.emerald500.withValues(alpha: 0.14);
    } else if (dropped) {
      color = AppColors.red500;
      bgColor = AppColors.red500.withValues(alpha: 0.14);
    } else {
      color = Colors.grey;
      bgColor = Colors.grey.withValues(alpha: 0.12);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            improved
                ? Icons.arrow_drop_up_rounded
                : (dropped
                      ? Icons.arrow_drop_down_rounded
                      : Icons.remove_rounded),
            color: color,
            size: 13.r,
          ),
          if (diff != 0) ...[
            SizedBox(width: 2.w),
            Text(
              '${diff.abs()}',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 9.sp,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
