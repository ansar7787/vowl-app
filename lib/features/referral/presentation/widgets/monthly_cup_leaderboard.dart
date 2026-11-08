import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/presentation/widgets/vowl_micro_loader.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/referral/domain/entities/referral_info.dart';

/// Top 50 Monthly Ambassador Cup Leaderboard with top 3 podium, qualification safeguards,
/// and pinned current user status.
class MonthlyCupLeaderboard extends StatefulWidget {
  final List<AmbassadorLeaderboardItem> items;
  final bool isLoading;
  final String? currentUserId;
  final int myMonthlyReferrals;
  final VoidCallback? onClaimPastMonth;
  final bool isClaimingPastMonth;
  final bool hasUnclaimedPastMonth;
  final VoidCallback? onInviteTap;

  const MonthlyCupLeaderboard({
    super.key,
    required this.items,
    this.isLoading = false,
    this.currentUserId,
    this.myMonthlyReferrals = 0,
    this.onClaimPastMonth,
    this.isClaimingPastMonth = false,
    this.hasUnclaimedPastMonth = false,
    this.onInviteTap,
  });

  @override
  State<MonthlyCupLeaderboard> createState() => _MonthlyCupLeaderboardState();
}

class _MonthlyCupLeaderboardState extends State<MonthlyCupLeaderboard> {
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
    final nextMonth = DateTime.utc(now.year, now.month + 1, 1);
    final diff = nextMonth.difference(now);
    if (mounted) {
      setState(() {
        _timeUntilReset = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  static String _rankPrizeText(int rank) {
    if (rank == 1) return '1 Mo VIP';
    if (rank == 2) return '1 Wk VIP';
    if (rank == 3) return '500🪙 + 3d VIP';
    if (rank <= 10) return '200 Coins';
    return 'Badge';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final surfaceColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);
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

    // Sort and limit to 50
    final displayItems = widget.items.take(50).toList();

    // Top 3 for podium
    final firstPlace = displayItems.isNotEmpty ? displayItems[0] : null;
    final secondPlace = displayItems.length > 1 ? displayItems[1] : null;
    final thirdPlace = displayItems.length > 2 ? displayItems[2] : null;

    // Remaining 4-50 ranks
    final remainingItems = displayItems.length > 3 ? displayItems.sublist(3) : <AmbassadorLeaderboardItem>[];

    // Current user rank
    final myItemIndex = displayItems.indexWhere((e) => e.userId == widget.currentUserId);
    final myRank = myItemIndex != -1 ? displayItems[myItemIndex].rank : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header: Title & TOP 50 Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(LucideIcons.trophy, size: 20.sp, color: const Color(0xFFF59E0B)),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Monthly Cup',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Text(
                'TOP 50 LEADERBOARD',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // 2. Rewards Card (Exact visual design matching WeeklyLeagueRewardsBanner)
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Monthly Rewards Title & Live Countdown Capsule
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
                          Icon(
                            LucideIcons.gift,
                            size: 14.sp,
                            color: const Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Monthly Rewards',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.slate900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
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
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald500,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Text(
                              '·',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w900,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          Icon(LucideIcons.clock, size: 10.5.sp, color: textSecondary),
                          SizedBox(width: 3.w),
                          Text(
                            remainingText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5.sp,
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
              SizedBox(height: 12.h),

              // 4-Column Prize Grid matching Leaderboard Weekly Rewards
              Row(
                children: [
                  Expanded(
                    child: _buildPrizeColumn(
                      rankLabel: '1st',
                      icon: LucideIcons.trophy,
                      primaryText: '1 Mo VIP',
                      secondaryText: 'Full Access',
                      accentColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _buildPrizeColumn(
                      rankLabel: '2nd',
                      icon: LucideIcons.medal,
                      primaryText: '1 Wk VIP',
                      secondaryText: 'Full Access',
                      accentColor: const Color(0xFF94A3B8),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _buildPrizeColumn(
                      rankLabel: '3rd',
                      icon: LucideIcons.award,
                      primaryText: '3d VIP',
                      coinAmount: 500,
                      accentColor: const Color(0xFFD97706),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _buildPrizeColumn(
                      rankLabel: '4-10th',
                      icon: LucideIcons.zap,
                      primaryText: 'Top 10',
                      coinAmount: 200,
                      accentColor: AppColors.indigo500,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // 3. Instruction Banner
        _buildQualificationMilestoneCard(
          isDark: isDark,
          myReferrals: widget.myMonthlyReferrals,
          myRank: myRank,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        // Unclaimed Past Month Reward Trigger
        if (widget.hasUnclaimedPastMonth && widget.onClaimPastMonth != null) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.amber500,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.gift, size: 20.sp, color: Colors.white),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Month\'s Prize Available!',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'You placed in the Ambassador Cup!',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.isClaimingPastMonth ? null : widget.onClaimPastMonth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD97706),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: widget.isClaimingPastMonth
                      ? const VowlMicroLoader(size: 14, color: Color(0xFFD97706))
                      : Text(
                          'Claim',
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 16.h),

        if (widget.isLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 28.h),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.sparkles, size: 24.sp, color: const Color(0xFFF59E0B)),
                  SizedBox(height: 8.h),
                  Text(
                    'Loading Monthly Cup Leaderboard...',
                    style: TextStyle(fontSize: 12.sp, color: textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else if (widget.items.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.trophy, size: 28.sp, color: AppColors.amber500),
                SizedBox(height: 8.h),
                Text(
                  'Be the First Ambassador This Month',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Invite a friend now to take the #1 spot and win 1 Month of VIP!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5.sp,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Top 3 Podium
          if (firstPlace != null) ...[
            _buildPodium(
              first: firstPlace,
              second: secondPlace,
              third: thirdPlace,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            SizedBox(height: 14.h),
          ],

          // Ranks 4 to 50 — Individual cards matching LeaderboardRankTile
          if (remainingItems.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: remainingItems.length,
              itemBuilder: (context, index) {
                final item = remainingItems[index];
                final isMe = item.userId == widget.currentUserId;
                return _buildLeaderboardTile(
                  item: item,
                  isMe: isMe,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),
        ],

        // Pinned Current User Standing
        if (widget.currentUserId != null) ...[
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: AppColors.indigo500.withValues(alpha: 0.35),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    myRank != null ? '#$myRank' : '-',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.indigo500,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Monthly Standing',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        myRank != null
                            ? 'Rank #$myRank • ${widget.myMonthlyReferrals} Friends'
                            : '${widget.myMonthlyReferrals} Friends Joined this Month',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: widget.myMonthlyReferrals >= 1
                        ? AppColors.emerald500.withValues(alpha: 0.15)
                        : AppColors.slate500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    widget.myMonthlyReferrals >= 1 ? 'QUALIFIED' : '0 / 1 INVITED',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: widget.myMonthlyReferrals >= 1
                          ? AppColors.emerald500
                          : textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQualificationMilestoneCard({
    required bool isDark,
    required int myReferrals,
    required int? myRank,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isQualified = myReferrals >= 1;

    if (isQualified) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.emerald500.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: AppColors.emerald500.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                size: 16.r,
                color: AppColors.emerald500,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'You are Qualified for Monthly Prizes!',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.emerald600,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    myRank != null
                        ? 'Ranked #$myRank • $myReferrals friends joined this month'
                        : '$myReferrals friends joined this month • Position active',
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.emerald500,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'QUALIFIED',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.indigo500.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.target,
                  size: 16.r,
                  color: AppColors.indigo500,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '1 Referral Needed to Enter Prize Pool',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.indigo950,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Minimum 1 referral required to qualify for monthly rewards.',
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.onInviteTap != null) ...[
            SizedBox(height: 10.h),
            ScaleButton(
              onTap: widget.onInviteTap,
              child: Container(
                height: 34.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.violet500],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.userPlus, size: 13.r, color: Colors.white),
                    SizedBox(width: 6.w),
                    Text(
                      'Invite Now',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static List<Color> _rankColors(int rank) {
    switch (rank) {
      case 1:
        return const [Color(0xFFFFD700), Color(0xFFFFA500)]; // Gold
      case 2:
        return const [Color(0xFFE0E0E0), Color(0xFFB0B0B0)]; // Silver
      case 3:
        return const [Color(0xFFCD7F32), Color(0xFFA3713B)]; // Bronze
      default:
        return const [AppColors.slate400, AppColors.slate600];
    }
  }

  Widget _buildPodium({
    required AmbassadorLeaderboardItem first,
    AmbassadorLeaderboardItem? second,
    AmbassadorLeaderboardItem? third,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          Expanded(
            child: second != null
                ? _buildPodiumColumn(
                    item: second,
                    rank: 2,
                    podiumHeight: 82.h,
                    isDark: isDark,
                    isMe: second.userId == widget.currentUserId,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(width: 8.w),

          // 1st Place (Center, Elevated)
          Expanded(
            child: _buildPodiumColumn(
              item: first,
              rank: 1,
              podiumHeight: 108.h,
              isDark: isDark,
              isMe: first.userId == widget.currentUserId,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isCenter: true,
            ),
          ),
          SizedBox(width: 8.w),

          // 3rd Place
          Expanded(
            child: third != null
                ? _buildPodiumColumn(
                    item: third,
                    rank: 3,
                    podiumHeight: 66.h,
                    isDark: isDark,
                    isMe: third.userId == widget.currentUserId,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required AmbassadorLeaderboardItem item,
    required int rank,
    required double podiumHeight,
    required bool isDark,
    required bool isMe,
    required Color textPrimary,
    required Color textSecondary,
    bool isCenter = false,
  }) {
    final hasReferrals = item.referralCount >= 1;
    final colors = _rankColors(rank);
    final avatarSize = isCenter ? 54.r : 44.r;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar with champion athletic ring + overlapping rank badge (Matching LeaderboardPodium)
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Single bold athletic champion border directly around avatar
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isMe ? 0.6 : 0.3),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(isCenter ? 3.r : 2.5.r),
              child: UserAvatar(
                photoUrl: item.photoUrl,
                size: avatarSize - (isCenter ? 6.r : 5.r),
              ),
            ),

            // Overlapping Rank badge (#1, #2, #3)
            Positioned(
              bottom: -5.h,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // "YOU" badge — only visible when current user is on podium
            if (isMe)
              Positioned(
                top: -2.h,
                right: -4.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'YOU',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 8.h),

        // Podium Column Pillar (Matching LeaderboardPodium)
        Container(
          width: double.infinity,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors[0].withValues(alpha: isDark ? 0.28 : 0.18),
                colors[1].withValues(alpha: isDark ? 0.08 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
            border: Border.all(
              color: colors[0].withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Player name
                  Text(
                    item.displayName.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCenter ? 12.sp : 10.5.sp,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Small pill card: lock icon with 0 ref, unlock icon with >0 ref
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
                    decoration: BoxDecoration(
                      color: hasReferrals
                          ? colors[0].withValues(alpha: isDark ? 0.22 : 0.14)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : AppColors.slate200.withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: hasReferrals
                            ? colors[0].withValues(alpha: 0.35)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : AppColors.slate300.withValues(alpha: 0.5)),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasReferrals ? LucideIcons.unlock : LucideIcons.lock,
                          size: 9.sp,
                          color: hasReferrals ? colors[0] : textSecondary,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          '${item.referralCount} Ref',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w800,
                            color: hasReferrals ? colors[0] : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrizeColumn({
    required String rankLabel,
    required IconData icon,
    required String primaryText,
    String? secondaryText,
    int? coinAmount,
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
            SizedBox(height: 3.h),
            Text(
              primaryText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900,
                height: 1.1,
              ),
            ),
            SizedBox(height: 3.h),
            if (coinAmount != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.coins,
                    size: 11.sp,
                    color: const Color(0xFFF59E0B),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '+$coinAmount',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B),
                      height: 1.1,
                    ),
                  ),
                ],
              )
            else if (secondaryText != null)
              Text(
                secondaryText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                  height: 1.1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile({
    required AmbassadorLeaderboardItem item,
    required bool isMe,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final bool hasReferrals = item.referralCount >= 1;
    final int rank = item.rank;
    final tierColor = rank <= 5
        ? AppColors.indigo500
        : rank <= 10
            ? AppColors.blue500
            : rank <= 25
                ? const Color(0xFF06B6D4)
                : (isDark ? AppColors.slate400 : AppColors.slate600);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isMe
              ? (isDark
                  ? AppColors.blue500.withValues(alpha: 0.6)
                  : AppColors.indigo500.withValues(alpha: 0.5))
              : borderColor,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank number with tier color (Matching LeaderboardRankTile)
          SizedBox(
            width: 28.w,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: tierColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8.w),

          // Avatar with subtle tier border
          UserAvatar(
            photoUrl: item.photoUrl,
            size: 34.r,
            border: Border.all(
              color: tierColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          SizedBox(width: 10.w),

          // Name & Referrals row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.displayName,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasReferrals) ...[
                      Icon(
                        LucideIcons.users,
                        size: 11.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${item.referralCount} Friends Joined',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ] else ...[
                      // Clean lock icon when not qualified (NO "unqualified" text badge)
                      Icon(
                        LucideIcons.lock,
                        size: 11.sp,
                        color: textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '0 Friends Joined',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Prize tier chip on the right
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: hasReferrals
                  ? tierColor.withValues(alpha: 0.12)
                  : AppColors.slate500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: hasReferrals
                    ? tierColor.withValues(alpha: 0.25)
                    : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Text(
              _rankPrizeText(rank),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: hasReferrals ? tierColor : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
