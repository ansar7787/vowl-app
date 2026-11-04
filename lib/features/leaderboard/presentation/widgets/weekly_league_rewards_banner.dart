import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/weekly_league_champion_dialog.dart';

class WeeklyLeagueRewardsBanner extends StatefulWidget {
  final UserEntity? currentUser;
  final Future<void> Function(int rank, int vipDays, int coins, String weekKey)? onClaimReward;
  final VoidCallback? onQuickMatch;

  const WeeklyLeagueRewardsBanner({
    super.key,
    this.currentUser,
    this.onClaimReward,
    this.onQuickMatch,
  });

  /// Computes the ISO-8601 week key (e.g. '2026-W45') for a given date.
  static String getCurrentWeekKey([DateTime? date]) {
    final now = (date ?? DateTime.now()).toUtc();
    final thursday = now.add(Duration(days: 4 - now.weekday));
    final firstDayOfYear = DateTime.utc(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(firstDayOfYear).inDays;
    final weekNumber = ((dayOfYear / 7).floor()) + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Computes the ISO-8601 week key for the previous week.
  static String getPreviousWeekKey([DateTime? date]) {
    final now = (date ?? DateTime.now()).toUtc();
    return getCurrentWeekKey(now.subtract(const Duration(days: 7)));
  }

  @override
  State<WeeklyLeagueRewardsBanner> createState() => _WeeklyLeagueRewardsBannerState();
}

class _WeeklyLeagueRewardsBannerState extends State<WeeklyLeagueRewardsBanner> {
  late Timer _timer;
  Duration _timeUntilReset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilReset();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _calculateTimeUntilReset());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateTimeUntilReset() {
    final now = DateTime.now().toUtc();
    // Sunday is weekday 7
    final daysUntilSunday = (7 - now.weekday) % 7;
    final nextSunday = DateTime.utc(now.year, now.month, now.day + daysUntilSunday, 23, 59, 59);
    final diff = nextSunday.difference(now);
    if (mounted) {
      setState(() {
        _timeUntilReset = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  void _openCelebrationDialog(String prevWeekKey) {
    final user = widget.currentUser;
    if (user == null) return;
    final rank = user.previousRank ?? 10;
    final vipDays = rank == 1 ? 7 : (rank == 2 ? 3 : (rank == 3 ? 1 : 0));
    final coins = rank == 1 ? 500 : (rank == 2 ? 300 : (rank == 3 ? 200 : 100));

    WeeklyLeagueChampionDialog.show(
      context: context,
      user: user,
      rank: rank,
      vipDays: vipDays,
      coins: coins,
      weekKey: prevWeekKey,
      onClaim: () async {
        await widget.onClaimReward?.call(rank, vipDays, coins, prevWeekKey);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final surfaceColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));

    final hours = _timeUntilReset.inHours;
    final days = _timeUntilReset.inDays;
    final remainingText = days > 0
        ? '${days}d ${hours % 24}h left'
        : '${hours}h ${_timeUntilReset.inMinutes % 60}m left';

    // Check offline win-back: Did user finish top 10 last week and hasn't claimed?
    final prevWeekKey = WeeklyLeagueRewardsBanner.getPreviousWeekKey();
    final hasUnclaimedLastWeek = widget.currentUser != null &&
        (widget.currentUser!.previousRank != null && widget.currentUser!.previousRank! <= 10) &&
        !widget.currentUser!.claimedWeeklyRewardWeekKeys.contains(prevWeekKey);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Division Tier & Live Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.zap, size: 12.sp, color: Colors.white),
                            SizedBox(width: 4.w),
                            Text(
                              'Gold Division',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Pulsing Live Indicator
                      Container(
                        width: 7.r,
                        height: 7.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.emerald500,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Time Left Capsule
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.clock, size: 12.sp, color: textSecondary),
                      SizedBox(width: 5.w),
                      Text(
                        remainingText,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // Podium Prize Grid (4 Tier Cards)
          Row(
            children: [
              Expanded(
                child: _buildPrizeColumn(
                  rankLabel: '1st',
                  icon: LucideIcons.crown,
                  rewardText: '7d VIP\n+500c',
                  accentColor: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildPrizeColumn(
                  rankLabel: '2nd',
                  icon: LucideIcons.medal,
                  rewardText: '3d VIP\n+300c',
                  accentColor: const Color(0xFF94A3B8),
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildPrizeColumn(
                  rankLabel: '3rd',
                  icon: LucideIcons.award,
                  rewardText: '1d VIP\n+200c',
                  accentColor: const Color(0xFFD97706),
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildPrizeColumn(
                  rankLabel: '4-10th',
                  icon: LucideIcons.zap,
                  rewardText: '100\nCoins',
                  accentColor: AppColors.indigo500,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          // High-Energy Quick Duel Action Bar
          if (widget.onQuickMatch != null && widget.currentUser != null) ...[
            SizedBox(height: 12.h),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (di.sl.isRegistered<HapticService>()) {
                    di.sl<HapticService>().light();
                  }
                  widget.onQuickMatch?.call();
                },
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.indigo500.withValues(alpha: isDark ? 0.22 : 0.12),
                        AppColors.blue500.withValues(alpha: isDark ? 0.16 : 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.35),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(LucideIcons.swords, size: 14.sp, color: Colors.white),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1v1 Arena Duel · Stake 30 Coins',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.slate900,
                              ),
                            ),
                            Text(
                              'Win 50 Coins & gain weekly XP instantly',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Duel ⚡',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Unclaimed Offline Win-Back Banner
          if (hasUnclaimedLastWeek) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    IllustrationColors.premiumGold.withValues(alpha: isDark ? 0.22 : 0.16),
                    AppColors.amber500.withValues(alpha: isDark ? 0.14 : 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: IllustrationColors.premiumGold.withValues(alpha: 0.5),
                  width: 1.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: IllustrationColors.premiumGold.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: IllustrationColors.premiumGold.withValues(alpha: 0.25),
                    ),
                    child: Icon(
                      LucideIcons.trophy,
                      size: 18.sp,
                      color: IllustrationColors.premiumGold,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rank #${widget.currentUser!.previousRank} Last Week! 🏆',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Tap to reveal & claim your champion rewards',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.slate300 : AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (di.sl.isRegistered<HapticService>()) {
                        di.sl<HapticService>().selection();
                      }
                      _openCelebrationDialog(prevWeekKey);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IllustrationColors.premiumGold,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Claim',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrizeColumn({
    required String rankLabel,
    required IconData icon,
    required String rewardText,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.w,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11.sp, color: accentColor),
                SizedBox(width: 3.w),
                Text(
                  rankLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              rewardText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.slate900,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

