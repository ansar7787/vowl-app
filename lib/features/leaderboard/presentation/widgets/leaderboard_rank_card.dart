import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Sticky card showing the current logged-in user's rank position, score, and league status.
class LeaderboardRankCard extends StatelessWidget {
  final List<UserEntity> allUsers;
  final bool isKids;
  final double collapseProgress;
  final VoidCallback? onTap;

  const LeaderboardRankCard({
    super.key,
    required this.allUsers,
    this.isKids = false,
    this.isWeekly = true,
    this.collapseProgress = 0.0,
    this.onTap,
  });

  final bool isWeekly;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    // Reactively watch for current user profile changes only.
    final currentUser = context.select<AuthBloc, UserEntity?>(
      (bloc) => bloc.state.user,
    );
    if (currentUser == null) return const SizedBox.shrink();

    final rankIndex = allUsers.indexWhere((u) => u.id == currentUser.id);
    final rank = rankIndex != -1 ? rankIndex + 1 : 0;
    final isRanked = rank > 0;
    final previousRank = currentUser.previousRank ??
        (rankIndex != -1 ? allUsers[rankIndex].previousRank : null);

    final String primaryScoreText;
    final String statusZoneText;
    final double relativeProgress;

    if (isKids) {
      primaryScoreText = '${currentUser.kidsTotalLevelsCompleted} Levels';
      statusZoneText = '${currentUser.kidsCoins} Stars ⭐ Collected';
      final topLevels = allUsers.isNotEmpty ? allUsers.first.kidsTotalLevelsCompleted : 1;
      relativeProgress = topLevels > 0 ? (currentUser.kidsTotalLevelsCompleted / topLevels).clamp(0.05, 1.0) : 0.05;
    } else if (isWeekly) {
      primaryScoreText = '${currentUser.currentWeeklyExp} Weekly XP';
      if (rank >= 1 && rank <= 3) {
        statusZoneText = '🏆 Podium Zone · VIP + Coins Reward';
      } else if (rank >= 4 && rank <= 10) {
        statusZoneText = '⚡ Top 10 Division · 100 Coins Reward';
      } else if (isRanked) {
        statusZoneText = '🏃 Contender Zone · Push for Top 10';
      } else {
        statusZoneText = 'Join this week\'s league race!';
      }
      final topWeeklyXp = allUsers.isNotEmpty ? allUsers.first.currentWeeklyExp : 1;
      relativeProgress = topWeeklyXp > 0 ? (currentUser.currentWeeklyExp / topWeeklyXp).clamp(0.05, 1.0) : 0.05;
    } else {
      primaryScoreText = '${currentUser.totalExp} Lifetime XP';
      statusZoneText = '${currentUser.totalLevelsCompleted} Quests · ${currentUser.currentStreak}d Streak 🔥';
      final topTotalXp = allUsers.isNotEmpty ? allUsers.first.totalExp : 1;
      relativeProgress = topTotalXp > 0 ? (currentUser.totalExp / topTotalXp).clamp(0.05, 1.0) : 0.05;
    }

    final contrastColor = Theme.of(context).colorScheme.onSurface;
    final secondaryTextColor = isDark ? Colors.white60 : AppColors.slate500;

    final card = Semantics(
      label: isRanked
          ? '${context.tr('leaderboard.your_standing', fallback: 'Your Standing')}. '
                '${context.tr('leaderboard.rank', fallback: 'Rank')}: $rank. '
                '$primaryScoreText. $statusZoneText.'
          : '${context.tr('leaderboard.join_competition', fallback: 'Join Competition')}. '
                '$primaryScoreText.',
      child: GlassTile(
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 8.h - (1.h * collapseProgress),
          ),
          borderRadius: BorderRadius.circular(22.r),
          blur: 0,
          borderColor: isMidnight
              ? Colors.white.withValues(alpha: 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.slate100),
          color: isMidnight
              ? AppColors.midnightSurface
              : (isDark ? const Color(0xFF131A29) : Colors.white),
          borderWidth: 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Rank circle (36.r matching avatar height perfectly)
                  Container(
                    width: 36.r,
                    height: 36.r,
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
                            isRanked ? '#$rank' : '?',
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
                  if (isRanked && !isKids && isWeekly) ...[
                    SizedBox(width: 5.w),
                    _buildRankChangeIndicator(previousRank ?? rank, rank),
                  ],
                  SizedBox(width: 8.w),
                  // Avatar (36.r — horizontally & vertically centered with rank)
                  UserAvatar(
                    photoUrl: currentUser.photoUrl,
                    size: 36.r,
                    border: Border.all(
                      color: isDark
                          ? Colors.white24
                          : Colors.black.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Name + label (vertically centered in row)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isRanked
                                ? context.tr(
                                    'leaderboard.your_standing',
                                    fallback: 'Your Standing',
                                  )
                                : context.tr(
                                    'leaderboard.join_competition',
                                    fallback: 'Join Competition',
                                  ),
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
                            currentUser.getSafeDisplayName(
                              fallback: context.tr(
                                'leaderboard.player',
                                fallback: 'Player',
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: contrastColor,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trailing Score & Status when pinned/collapsed (smooth fade-in)
                  if (collapseProgress > 0.35) ...[
                    SizedBox(width: 8.w),
                    Opacity(
                      opacity: ((collapseProgress - 0.35) / 0.65).clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              primaryScoreText,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.indigo400
                                    : AppColors.indigo600,
                              ),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isWeekly
                                  ? (rank >= 1 && rank <= 3
                                      ? '🏆 Podium'
                                      : (rank <= 10 ? '⚡ Top 10' : '🏃 Contender'))
                                  : (isKids
                                      ? '${currentUser.kidsCoins} ⭐'
                                      : '${currentUser.currentStreak}d 🔥'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w700,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (collapseProgress < 1.0)
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 1.0 - collapseProgress,
                    child: Opacity(
                      opacity: 1.0 - collapseProgress,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 10.h),
                          // Progress bar with smooth relative fill
                          Stack(
                            children: [
                              Container(
                                height: 5.h,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(3.r),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: relativeProgress.clamp(0.05, 1.0),
                                child: Container(
                                  height: 5.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.indigo500,
                                    borderRadius: BorderRadius.circular(
                                      3.r,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  statusZoneText,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.slate700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  primaryScoreText,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.indigo400
                                        : AppColors.indigo600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            improved
                ? Icons.arrow_upward_rounded
                : (dropped ? Icons.arrow_downward_rounded : Icons.remove_rounded),
            color: color,
            size: 10.r,
          ),
          if (diff != 0) ...[
            SizedBox(width: 1.5.w),
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
