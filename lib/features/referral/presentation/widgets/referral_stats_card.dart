import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';

class ReferralStatsCard extends StatelessWidget {
  final String referralCode;
  final int lifetimeCount;
  final int monthlyCount;
  final bool hasClaimedReferral;
  final bool isCopied;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onEnterCode;

  const ReferralStatsCard({
    super.key,
    required this.referralCode,
    required this.lifetimeCount,
    required this.monthlyCount,
    required this.hasClaimedReferral,
    required this.isCopied,
    required this.onCopy,
    required this.onShare,
    required this.onEnterCode,
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
          // Dual Counters
          Row(
            children: [
              Expanded(
                child: _buildCounterTile(
                  title: 'Lifetime Joined',
                  value: '$lifetimeCount',
                  subtitle: '+100 🪙 each',
                  icon: LucideIcons.users,
                  accentColor: AppColors.indigo500,
                  isDark: isDark,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildCounterTile(
                  title: 'Monthly Cup',
                  value: '$monthlyCount',
                  subtitle: 'Ends in ${DateTime.now().toUtc().month == 12 ? 31 : 30 - DateTime.now().toUtc().day}d',
                  icon: LucideIcons.trophy,
                  accentColor: const Color(0xFFF59E0B),
                  isDark: isDark,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // Referral Code Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? AppColors.slate800 : const Color(0xFFCBD5E1),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 18.sp,
                  color: AppColors.indigo500,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR AMBASSADOR CODE',
                        style: TextStyle(
                          fontSize: 10.sp,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        referralCode,
                        style: TextStyle(
                          fontSize: 16.sp,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Copy Action
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isCopied ? AppColors.emerald500.withValues(alpha: 0.15) : AppColors.indigo500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCopied ? LucideIcons.check : LucideIcons.copy,
                            size: 14.sp,
                            color: isCopied ? AppColors.emerald500 : AppColors.indigo500,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            isCopied ? 'Copied' : 'Copy',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isCopied ? AppColors.emerald500 : AppColors.indigo500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // Primary Share Button
          ElevatedButton.icon(
            onPressed: onShare,
            icon: Icon(LucideIcons.share2, size: 16.sp),
            label: Text(
              'Share Invite Link',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
          ),

          // Claim friend code entry (only visible if user hasn't claimed one yet)
          if (!hasClaimedReferral) ...[
            SizedBox(height: 10.h),
            TextButton.icon(
              onPressed: onEnterCode,
              icon: Icon(
                LucideIcons.gift,
                size: 14.sp,
                color: AppColors.indigo500,
              ),
              label: Text(
                'Have a friend\'s code? Claim 100 Coins + 1 Day VIP',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.indigo500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D121F) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.sp, color: accentColor),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

