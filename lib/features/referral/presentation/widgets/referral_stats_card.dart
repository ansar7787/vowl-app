import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';

class ReferralStatsCard extends StatelessWidget {
  final String referralCode;
  final int lifetimeCount;
  final int monthlyCount;
  final bool hasClaimedReferral;
  final String? pendingReferralCode;
  final String? referredBy;
  final bool hasActivePremium;
  final DateTime? premiumExpiryDate;
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
    this.pendingReferralCode,
    this.referredBy,
    this.hasActivePremium = false,
    this.premiumExpiryDate,
    required this.isCopied,
    required this.onCopy,
    required this.onShare,
    required this.onEnterCode,
  });

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
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

    final nowUtc = DateTime.now().toUtc();
    final nextMonthUtc = DateTime.utc(nowUtc.year, nowUtc.month + 1, 1);
    final daysRemainingInMonth = nextMonthUtc.difference(nowUtc).inDays.clamp(0, 31);

    return Container(
      padding: EdgeInsets.all(AppSpacing.card),
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
                  subtitle: 'Ends in ${daysRemainingInMonth}d',
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

          SizedBox(height: 12.h),

          // VIP Stacking Status Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: hasActivePremium
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                  : AppColors.indigo500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: hasActivePremium
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                    : AppColors.indigo500.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasActivePremium ? LucideIcons.crown : LucideIcons.sparkles,
                  size: 15.sp,
                  color: hasActivePremium ? const Color(0xFFF59E0B) : AppColors.indigo500,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    hasActivePremium && premiumExpiryDate != null
                        ? 'VIP Active until ${_formatDate(premiumExpiryDate!)} • Each friend extends by +24 Hours'
                        : 'Get 100 Coins + 1 Day VIP for each friend who completes Level 1!',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: hasActivePremium
                          ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                          : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA)),
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
              'Share Invite Link & Card',
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

          // Section 1 Code Status / Input
          SizedBox(height: 12.h),
          if (hasClaimedReferral) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.checkCircle2, size: 16.sp, color: AppColors.emerald500),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Invite Pass Claimed (${referredBy ?? 'Ambassador'}) • 100 Coins & VIP Active!',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (pendingReferralCode != null && pendingReferralCode!.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, size: 16.sp, color: const Color(0xFFF59E0B)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pass "$pendingReferralCode" Saved!',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Complete Adventure Level 1 to activate your 100 Coins & 1 Day VIP!',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: onEnterCode,
              icon: Icon(
                LucideIcons.gift,
                size: 14.sp,
                color: AppColors.indigo500,
              ),
              label: Text(
                'Have a friend\'s code? Enter pass for 100 Coins + 1 Day VIP',
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

