import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_micro_loader.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/utils/weekly_league_reward_helper.dart';

/// Modern inline claim card shown on the Home dashboard when the logged-in user
/// placed in the Weekly League Top 10 last week and has not yet claimed their prize.
///
/// Features:
/// - Prominently celebrates winner status (Champion 1st, Silver 2nd, Bronze 3rd, Top 10).
/// - Instant 1-tap claim execution with zero redundant modals.
/// - Triggers celebratory confetti fanfare upon claim.
class WeeklyLeagueRewardHomeCard extends StatefulWidget {
  final UserEntity user;

  const WeeklyLeagueRewardHomeCard({super.key, required this.user});

  @override
  State<WeeklyLeagueRewardHomeCard> createState() =>
      _WeeklyLeagueRewardHomeCardState();
}

class _WeeklyLeagueRewardHomeCardState
    extends State<WeeklyLeagueRewardHomeCard> {
  bool _isClaiming = false;

  Future<void> _handleClaim(
    int rank,
    int vipDays,
    int coins,
    String weekKey,
  ) async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }

    try {
      await WeeklyLeagueRewardHelper.claimReward(
        context: context,
        user: widget.user,
        rank: rank,
        vipDays: vipDays,
        coins: coins,
        weekKey: weekKey,
        showCelebrationDialog: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!WeeklyLeagueRewardHelper.hasUnclaimedReward(widget.user)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final rank = widget.user.previousRank ?? 10;
    final vipDays = WeeklyLeagueRewardHelper.getVipDays(rank);
    final coins = WeeklyLeagueRewardHelper.getCoins(rank);
    final weekKey =
        widget.user.previousRankWeekKey ??
        WeeklyLeagueRewardHelper.getPreviousWeekKey();

    final title = WeeklyLeagueRewardHelper.getRankTitle(rank);
    final subtitle =
        '${WeeklyLeagueRewardHelper.getRankSubtitle(rank)} · ${WeeklyLeagueRewardHelper.getPrizeSummary(rank)}';

    final Color accentColor;
    final IconData icon;
    switch (rank) {
      case 1:
        accentColor = IllustrationColors.premiumGold;
        icon = LucideIcons.trophy;
        break;
      case 2:
        accentColor = const Color(0xFFC0C0C0);
        icon = LucideIcons.medal;
        break;
      case 3:
        accentColor = const Color(0xFFCD7F32);
        icon = LucideIcons.award;
        break;
      default:
        accentColor = AppColors.indigo500;
        icon = LucideIcons.zap;
    }

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(
          left: AppSpacing.screen,
          right: AppSpacing.screen,
          top: 10.h,
          bottom: 2.h,
        ),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.45 : 0.35),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.16 : 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Glowing Icon Badge
            Container(
              padding: EdgeInsets.all(9.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.45),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, size: 20.sp, color: accentColor),
            ),
            SizedBox(width: 12.w),

            // Title & Subtitle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),

            // 1-Tap Claim Button
            ScaleButton(
              onTap: _isClaiming
                  ? null
                  : () => _handleClaim(rank, vipDays, coins, weekKey),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.5.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isClaiming
                    ? const VowlMicroLoader(size: 14, color: Colors.white)
                    : Text(
                        'Claim',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: rank == 1 ? Colors.black : Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

