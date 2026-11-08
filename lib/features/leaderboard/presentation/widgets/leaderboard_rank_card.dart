import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Sticky bottom card showing the current logged-in user's rank position and completed levels.
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
      primaryScoreText = '${currentUser.kidsTotalLevelsCompleted} Levels Mastered';
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
            vertical: 10.h - (3.h * collapseProgress),
          ),
          borderRadius: BorderRadius.circular(24.r),
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
                children: [
                  // Rank circle & Change Indicator (compact 2026 styling, zero shadows)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        SizedBox(height: 3.h),
                        _buildRankChangeIndicator(previousRank ?? rank, rank),
                      ],
                    ],
                  ),
                  SizedBox(width: 8.w),
                  // Avatar
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
                  // Name + label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          SizedBox(height: 12.h),
                          // Progress bar with animated fill
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
                                tween: Tween(
                                  begin: 0.0,
                                  end: relativeProgress.clamp(0.05, 1.0),
                                ),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) {
                                  return FractionallySizedBox(
                                    widthFactor: value,
                                    child: Container(
                                      height: 6.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.indigo500,
                                        borderRadius: BorderRadius.circular(
                                          3.r,
                                        ),
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

    final interactiveCard = onTap != null
        ? GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: card,
          )
        : card;

    if (VowlMotion.shouldReduceMotion(context)) {
      return interactiveCard;
    }

    return interactiveCard
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 350))
        .slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildRankChangeIndicator(int previousRank, int currentRank) {
    final diff = previousRank - currentRank;
    if (diff > 0) {
      // Improved rank (e.g. from 10 to 5)
      return SizedBox(
        height: 12.h,
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
          mainAxisSize: MainAxisSize.min,
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
      // Stayed the same
      return SizedBox(
        height: 12.h,
        child: Center(
          child: Container(
            width: 8.w,
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
