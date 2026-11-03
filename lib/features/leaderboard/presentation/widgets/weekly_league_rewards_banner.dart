import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class WeeklyLeagueRewardsBanner extends StatefulWidget {
  final UserEntity? currentUser;
  final Function(int rank, int vipDays, int coins, String weekKey)? onClaimReward;
  final VoidCallback? onQuickMatch;

  const WeeklyLeagueRewardsBanner({
    super.key,
    this.currentUser,
    this.onClaimReward,
    this.onQuickMatch,
  });

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

  static String getPreviousWeekKey() {
    final now = DateTime.now().toUtc();
    // Subtract 7 days to get last week's ISO week
    final lastWeek = now.subtract(const Duration(days: 7));
    final weekNumber = ((lastWeek.difference(DateTime.utc(lastWeek.year, 1, 1)).inDays) / 7).ceil();
    return '${lastWeek.year}-W${weekNumber.toString().padLeft(2, '0')}';
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
    final textPrimary = isDark ? Colors.white : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));

    final hours = _timeUntilReset.inHours;
    final days = _timeUntilReset.inDays;
    final remainingText = days > 0
        ? '${days}d ${hours % 24}h left'
        : '${hours}h ${_timeUntilReset.inMinutes % 60}m left';

    // Check offline win-back: Did user finish top 10 last week and hasn't claimed?
    final prevWeekKey = getPreviousWeekKey();
    final hasUnclaimedLastWeek = widget.currentUser != null &&
        (widget.currentUser!.previousRank != null && widget.currentUser!.previousRank! <= 10) &&
        !widget.currentUser!.claimedWeeklyRewardWeekKeys.contains(prevWeekKey);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(LucideIcons.flame, size: 16.sp, color: const Color(0xFFF59E0B)),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        'Weekly League Podium',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.clock, size: 11.sp, color: textSecondary),
                    SizedBox(width: 4.w),
                    Text(
                      remainingText,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // Podium Prize Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPrizeBadge('🥇 1st', '+3 Days VIP', const Color(0xFFF59E0B), isDark),
                SizedBox(width: 6.w),
                _buildPrizeBadge('🥈 2nd', '+1 Day VIP', const Color(0xFF94A3B8), isDark),
                SizedBox(width: 6.w),
                _buildPrizeBadge('🥉 3rd', '150 Coins', const Color(0xFFD97706), isDark),
                SizedBox(width: 6.w),
                _buildPrizeBadge('🏅 4-10th', '50 Coins', AppColors.indigo500, isDark),
              ],
            ),
          ),

          // Quick Match 30-Coin Duel CTA
          if (widget.onQuickMatch != null && widget.currentUser != null) ...[
            SizedBox(height: 10.h),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (di.sl.isRegistered<HapticService>()) {
                    di.sl<HapticService>().light();
                  }
                  widget.onQuickMatch?.call();
                },
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.indigo500.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.swords, size: 14.sp, color: AppColors.indigo500),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Quick Duel (30 Coins) · 3s Instant Match',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.indigo600,
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
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.gift, size: 16.sp, color: AppColors.emerald500),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Rank #${widget.currentUser!.previousRank} last week! Claim your prize.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF065F46),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (di.sl.isRegistered<HapticService>()) {
                        di.sl<HapticService>().light();
                      }
                      final rank = widget.currentUser!.previousRank ?? 10;
                      final vipDays = rank == 1 ? 3 : (rank == 2 ? 1 : 0);
                      final coins = rank == 3 ? 150 : (rank > 3 ? 50 : 0);
                      widget.onClaimReward?.call(rank, vipDays, coins, prevWeekKey);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald500,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Claim',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
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

  Widget _buildPrizeBadge(String label, String prize, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: color),
          ),
          SizedBox(width: 4.w),
          Text(
            prize,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

