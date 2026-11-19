import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/utils/weekly_league_reward_helper.dart';

/// Modal bottom sheet showcasing last week's top 10 winners, their ranks,
/// XP earned, and exact prizes awarded.
///
/// If winner records have not yet been generated for the past week, displays
/// an elegant prize distribution breakdown and the current user's placement.
class LastWeekWinnersBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> winners;
  final List<UserEntity>? allUsers;
  final UserEntity? currentUser;
  final String? weekKey;

  const LastWeekWinnersBottomSheet({
    super.key,
    required this.winners,
    this.allUsers,
    this.currentUser,
    this.weekKey,
  });

  /// Displays the bottom sheet with clean animation and safe-area insets.
  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> winners,
    List<UserEntity>? allUsers,
    UserEntity? currentUser,
    String? weekKey,
  }) {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LastWeekWinnersBottomSheet(
        winners: winners,
        allUsers: allUsers,
        currentUser: currentUser,
        weekKey: weekKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final surfaceColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark
            ? const Color(0xFF131A29)
            : (tokens?.surface ?? Colors.white));
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);
    final textPrimary = isDark
        ? Colors.white
        : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark
        ? AppColors.slate400
        : (tokens?.textSecondary ?? const Color(0xFF64748B));

    final systemBottomPadding = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    final safeBottom =
        (systemBottomPadding > 0 ? systemBottomPadding : 16.h) + 16.h;

    // Resilient fallback resolution:
    // 1. Direct winners list from cloud function
    // 2. Synthesize from allUsers where previousRank <= 10
    final List<Map<String, dynamic>> resolvedWinners;
    if (winners.isNotEmpty) {
      resolvedWinners = winners;
    } else if (allUsers != null && allUsers!.isNotEmpty) {
      final candidates = allUsers!
          .where((u) =>
              u.previousRank != null &&
              u.previousRank! >= 1 &&
              u.previousRank! <= 10)
          .toList()
        ..sort((a, b) => a.previousRank!.compareTo(b.previousRank!));

      resolvedWinners = candidates
          .map((u) => {
                'id': u.id,
                'rank': u.previousRank!,
                'displayName': u.safeDisplayName,
                'photoUrl': u.photoUrl,
                'weeklyXp': u.currentWeeklyExp,
                'weekKey': u.previousRankWeekKey,
              })
          .toList();
    } else {
      resolvedWinners = const [];
    }

    final resolvedWeekKey = weekKey ??
        currentUser?.previousRankWeekKey ??
        WeeklyLeagueRewardHelper.getPreviousWeekKey();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, safeBottom),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: borderColor, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.slate300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Sheet Title & Close Icon
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.trophy,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr(
                          'leaderboard.last_week_champions_title',
                          fallback: "Last Week's Champions",
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Top 10 League Winners · $resolvedWeekKey',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.06),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18.r,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (resolvedWinners.isNotEmpty) ...[
                      ...resolvedWinners.map((winner) {
                        final rank = (winner['rank'] as num?)?.toInt() ?? 10;
                        final name = (winner['displayName'] as String?) ??
                            'Vowl Learner';
                        final photoUrl = winner['photoUrl'] as String?;
                        final weeklyXp =
                            (winner['weeklyXp'] as num?)?.toInt() ?? 0;
                        final isMe = currentUser?.id == winner['id'];

                        return _buildWinnerCard(
                          context: context,
                          rank: rank,
                          displayName: name,
                          photoUrl: photoUrl,
                          weeklyXp: weeklyXp,
                          isMe: isMe,
                          isDark: isDark,
                          isMidnight: isMidnight,
                        );
                      }),
                    ] else ...[
                      // Empty state / Fallback with prize breakdown & user status
                      _buildEmptyFallback(
                        context: context,
                        isDark: isDark,
                        isMidnight: isMidnight,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Got it button
            ScaleButton(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  context.tr('common.got_it', fallback: 'Got It!'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerCard({
    required BuildContext context,
    required int rank,
    required String displayName,
    required String? photoUrl,
    required int weeklyXp,
    required bool isMe,
    required bool isDark,
    required bool isMidnight,
  }) {
    final Color rankColor;
    final String rankLabel;
    final IconData rankIcon;

    switch (rank) {
      case 1:
        rankColor = IllustrationColors.premiumGold;
        rankLabel = '1st';
        rankIcon = LucideIcons.trophy;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        rankLabel = '2nd';
        rankIcon = LucideIcons.medal;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        rankLabel = '3rd';
        rankIcon = LucideIcons.award;
        break;
      default:
        rankColor = AppColors.indigo500;
        rankLabel = '#$rank';
        rankIcon = LucideIcons.zap;
    }

    final prizeSummary = WeeklyLeagueRewardHelper.getPrizeSummary(rank);
    final cardBg = isMe
        ? (isDark
            ? rankColor.withValues(alpha: 0.15)
            : rankColor.withValues(alpha: 0.1))
        : (isMidnight
            ? const Color(0xFF0F1523)
            : (isDark ? const Color(0xFF1A2338) : const Color(0xFFF8FAFC)));

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isMe
              ? rankColor
              : rankColor.withValues(alpha: isDark ? 0.25 : 0.15),
          width: isMe ? 1.5.w : 1.w,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.18),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.4),
                width: 1.w,
              ),
            ),
            alignment: Alignment.center,
            child: rank <= 3
                ? Icon(rankIcon, size: 16.sp, color: rankColor)
                : Text(
                    rankLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: rankColor,
                    ),
                  ),
          ),
          SizedBox(width: 10.w),

          // User Avatar
          UserAvatar(
            photoUrl: photoUrl,
            size: 34.r,
            border: Border.all(
              color: rankColor.withValues(alpha: 0.4),
              width: 1.2.r,
            ),
          ),
          SizedBox(width: 10.w),

          // Name and XP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: rank == 1 ? Colors.black : Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(
                      LucideIcons.flame,
                      size: 11.sp,
                      color: AppColors.amber500,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '$weeklyXp XP',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate300 : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // Prize Pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              prizeSummary,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: rankColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFallback({
    required BuildContext context,
    required bool isDark,
    required bool isMidnight,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final userRank = currentUser?.previousRank;
    final hasUserWon = userRank != null && userRank <= 10;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasUserWon) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    IllustrationColors.premiumGold.withValues(alpha: 0.2),
                    AppColors.amber500.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: IllustrationColors.premiumGold.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.award,
                    size: 26.sp,
                    color: IllustrationColors.premiumGold,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You placed Rank #$userRank last week!',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Prize: ${WeeklyLeagueRewardHelper.getPrizeSummary(userRank)}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: IllustrationColors.premiumGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
          ],

          // Prize structure overview
          Text(
            'Weekly League Prize Tiers',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 8.h),

          _buildTierRow('1st Place', '7 Days VIP + 500 Coins + Aura',
              IllustrationColors.premiumGold, LucideIcons.trophy, isDark),
          SizedBox(height: 6.h),
          _buildTierRow('2nd Place', '3 Days VIP + 300 Coins + Medal',
              const Color(0xFFC0C0C0), LucideIcons.medal, isDark),
          SizedBox(height: 6.h),
          _buildTierRow('3rd Place', '1 Day VIP + 200 Coins + Podium',
              const Color(0xFFCD7F32), LucideIcons.award, isDark),
          SizedBox(height: 6.h),
          _buildTierRow('Ranks 4-10', '100 Coins + Finisher Ribbon',
              AppColors.indigo500, LucideIcons.zap, isDark),

          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: 14.sp,
                  color: textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Weekly results finalize every Sunday at 23:59 UTC. Complete quests to secure a top 10 spot!',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow(String title, String reward, Color color, IconData icon,
      bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            reward,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }
}
