import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/presentation/widgets/vowl_micro_loader.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/referral/domain/entities/referral_info.dart';

/// Top 50 Monthly Ambassador Cup Leaderboard with top 3 podium, qualification safeguards,
/// and pinned current user status.
class MonthlyCupLeaderboard extends StatelessWidget {
  final List<AmbassadorLeaderboardItem> items;
  final bool isLoading;
  final String? currentUserId;
  final int myMonthlyReferrals;
  final VoidCallback? onClaimPastMonth;
  final bool isClaimingPastMonth;
  final bool hasUnclaimedPastMonth;

  const MonthlyCupLeaderboard({
    super.key,
    required this.items,
    this.isLoading = false,
    this.currentUserId,
    this.myMonthlyReferrals = 0,
    this.onClaimPastMonth,
    this.isClaimingPastMonth = false,
    this.hasUnclaimedPastMonth = false,
  });

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

    // Sort and limit to 50
    final displayItems = items.take(50).toList();

    // Top 3 for podium
    final firstPlace = displayItems.isNotEmpty ? displayItems[0] : null;
    final secondPlace = displayItems.length > 1 ? displayItems[1] : null;
    final thirdPlace = displayItems.length > 2 ? displayItems[2] : null;

    // Remaining 4-50 ranks
    final remainingItems = displayItems.length > 3 ? displayItems.sublist(3) : <AmbassadorLeaderboardItem>[];

    // Current user rank
    final myItemIndex = displayItems.indexWhere((e) => e.userId == currentUserId);
    final myRank = myItemIndex != -1 ? displayItems[myItemIndex].rank : null;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(LucideIcons.trophy, size: 20.sp, color: const Color(0xFFF59E0B)),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'Monthly Ambassador Cup',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
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
                ),
                child: Text(
                  'TOP 50 LEADERBOARD',
                  style: TextStyle(
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

          // Prize structure pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPrizeChip('🥇 1st', '1 Mo VIP', const Color(0xFFF59E0B), isDark),
                SizedBox(width: 8.w),
                _buildPrizeChip('🥈 2nd', '1 Wk VIP', const Color(0xFF94A3B8), isDark),
                SizedBox(width: 8.w),
                _buildPrizeChip('🥉 3rd', '500🪙 + 3D VIP', const Color(0xFFD97706), isDark),
                SizedBox(width: 8.w),
                _buildPrizeChip('🏅 4-10th', '200 Coins', AppColors.indigo500, isDark),
                SizedBox(width: 8.w),
                _buildPrizeChip('🎖️ 11-50th', 'Badge', const Color(0xFF10B981), isDark),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Qualification Rule Notice Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.shieldAlert,
                  size: 14.sp,
                  color: const Color(0xFFF59E0B),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Rule: Ambassadors must have at least 1 referral to qualify for Cup rewards. 0-referral ranks receive no rewards.',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Unclaimed Past Month Reward Trigger
          if (hasUnclaimedPastMonth && onClaimPastMonth != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(12.r),
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
                    onPressed: isClaimingPastMonth ? null : onClaimPastMonth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD97706),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: isClaimingPastMonth
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

          if (isLoading)
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
          else if (items.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.crown, size: 28.sp, color: AppColors.indigo500),
                  SizedBox(height: 8.h),
                  Text(
                    'Be the First Ambassador This Month',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Invite a friend now to take the #1 spot and win 1 Month of VIP!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
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
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              SizedBox(height: 16.h),
            ],

            // Ranks 4 to 50
            if (remainingItems.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: remainingItems.length,
                separatorBuilder: (_, _) => Divider(
                  color: isDark ? AppColors.slate800 : const Color(0xFFE2E8F0),
                  height: 12.h,
                ),
                itemBuilder: (context, index) {
                  final item = remainingItems[index];
                  final isMe = item.userId == currentUserId;
                  return _buildLeaderboardTile(
                    item: item,
                    isMe: isMe,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  );
                },
              ),
          ],

          // Pinned Current User Standing
          if (currentUserId != null) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D121F) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.w,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      myRank != null ? '#$myRank' : '-',
                      style: TextStyle(
                        fontSize: 11.sp,
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
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          myRank != null
                              ? 'Rank #$myRank • $myMonthlyReferrals Referrals'
                              : 'Unranked • $myMonthlyReferrals Referrals (Invite 1 to qualify)',
                          style: TextStyle(
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
                      color: myMonthlyReferrals >= 1
                          ? AppColors.emerald500.withValues(alpha: 0.15)
                          : AppColors.slate500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      myMonthlyReferrals >= 1 ? 'QUALIFIED' : 'NEED 1+',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: myMonthlyReferrals >= 1
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
      ),
    );
  }

  Widget _buildPodium({
    required AmbassadorLeaderboardItem first,
    AmbassadorLeaderboardItem? second,
    AmbassadorLeaderboardItem? third,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
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
                    badgeColor: const Color(0xFF94A3B8),
                    podiumHeight: 80.h,
                    isDark: isDark,
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
              badgeColor: const Color(0xFFF59E0B),
              podiumHeight: 104.h,
              isDark: isDark,
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
                    badgeColor: const Color(0xFFD97706),
                    podiumHeight: 64.h,
                    isDark: isDark,
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
    required Color badgeColor,
    required double podiumHeight,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    bool isCenter = false,
  }) {
    final hasReferrals = item.referralCount >= 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for #1
        if (isCenter)
          Icon(LucideIcons.crown, size: 18.sp, color: const Color(0xFFF59E0B)),
        if (isCenter) SizedBox(height: 2.h),

        // Avatar
        UserAvatar(
          photoUrl: item.photoUrl,
          size: isCenter ? 44.r : 36.r,
        ),
        SizedBox(height: 6.h),

        // Name
        Text(
          item.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCenter ? 12.sp : 11.sp,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 2.h),

        // Count / Qualified
        Text(
          hasReferrals ? '${item.referralCount} Ref' : '0 Ref',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: hasReferrals ? badgeColor : textSecondary,
          ),
        ),
        SizedBox(height: 6.h),

        // Podium Block
        Container(
          height: podiumHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
            border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: isCenter ? 18.sp : 15.sp,
                  fontWeight: FontWeight.w900,
                  color: badgeColor,
                ),
              ),
              Text(
                item.rewardTier.prizeDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w700,
                  color: hasReferrals ? textPrimary : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrizeChip(String label, String prize, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: color),
          ),
          SizedBox(width: 4.w),
          Text(
            prize,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile({
    required AmbassadorLeaderboardItem item,
    required bool isMe,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final bool hasReferrals = item.referralCount >= 1;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          // Rank Badge
          SizedBox(
            width: 28.w,
            child: Text(
              '#${item.rank}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: textSecondary,
              ),
            ),
          ),
          SizedBox(width: 4.w),

          // Avatar
          UserAvatar(
            photoUrl: item.photoUrl,
            size: 28.r,
          ),
          SizedBox(width: 10.w),

          // Name
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                      color: isMe ? AppColors.indigo500 : textPrimary,
                    ),
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'YOU',
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.indigo500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Qualification status / Count
          if (!hasReferrals)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppColors.slate500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '0 ref • Unqualified',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.users, size: 12.sp, color: AppColors.indigo500),
                  SizedBox(width: 4.w),
                  Text(
                    '${item.referralCount}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
