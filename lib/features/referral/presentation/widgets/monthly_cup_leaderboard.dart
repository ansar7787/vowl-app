import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/referral/domain/entities/referral_info.dart';

class MonthlyCupLeaderboard extends StatelessWidget {
  final List<AmbassadorLeaderboardItem> items;
  final bool isLoading;

  const MonthlyCupLeaderboard({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.midnightSurface : (tokens?.surface ?? Colors.white);
    final borderColor = isDark ? AppColors.slate800 : (tokens?.border ?? const Color(0xFFE2E8F0));
    final textPrimary = isDark ? Colors.white : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));

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
                    Icon(LucideIcons.trophy, size: 18.sp, color: const Color(0xFFF59E0B)),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'Monthly Ambassador Cup',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
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
                  'TOP 10 PRIZES',
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
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
              ],
            ),
          ),

          SizedBox(height: 16.h),

          if (isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
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
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(
                color: isDark ? AppColors.slate800 : const Color(0xFFE2E8F0),
                height: 12.h,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildLeaderboardTile(
                  item: item,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),
        ],
      ),
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
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    Color rankColor;
    if (item.rank == 1) {
      rankColor = const Color(0xFFF59E0B);
    } else if (item.rank == 2) {
      rankColor = const Color(0xFF94A3B8);
    } else if (item.rank == 3) {
      rankColor = const Color(0xFFD97706);
    } else {
      rankColor = textSecondary;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          // Rank Badge
          SizedBox(
            width: 24.w,
            child: Text(
              '#${item.rank}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: rankColor,
              ),
            ),
          ),
          SizedBox(width: 8.w),

          // Avatar / Placeholder
          CircleAvatar(
            radius: 14.r,
            backgroundColor: AppColors.indigo500.withValues(alpha: 0.15),
            backgroundImage: (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                ? NetworkImage(item.photoUrl!)
                : null,
            child: (item.photoUrl == null || item.photoUrl!.isEmpty)
                ? Text(
                    item.displayName.isNotEmpty ? item.displayName[0].toUpperCase() : 'V',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 10.w),

          // Name
          Expanded(
            child: Text(
              item.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),

          // Score / Count
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
