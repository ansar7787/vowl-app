import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Modern, human-centric Ambassador Referral Stats Card.
///
/// Features:
/// - Friendly, encouraging headline and clear mutual reward description.
/// - Symmetrical Dual Stats Bento (Lifetime Joined & Monthly Cup).
/// - High-contrast Invite Code Box with instant copy feedback.
/// - VIP bonus extension tracker.
/// - Tactile primary [Share Invite Link & Card] button.
/// - Clean claim status or friend's invite code redemption trigger.
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
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final surfaceColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate900 : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    final nowUtc = DateTime.now().toUtc();
    final nextMonthUtc = DateTime.utc(nowUtc.year, nowUtc.month + 1, 1);
    final daysRemainingInMonth = nextMonthUtc
        .difference(nowUtc)
        .inDays
        .clamp(0, 31);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Hero Header & Mutual Reward Promise ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.violet500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite Friends, Earn Together',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Share Vowl with friends. When they finish Level 1, both of you unlock 100 Bonus Coins and 1 Day of VIP access.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // ── 2. Dual Stats Bento Grid ──
          Row(
            children: [
              Expanded(
                child: _buildBentoPod(
                  title: 'Friends Joined',
                  value: '$lifetimeCount',
                  subtitle: '+100 🪙 each',
                  icon: Icons.people_alt_rounded,
                  accentColor: AppColors.indigo500,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildBentoPod(
                  title: 'Monthly Cup',
                  value: '$monthlyCount',
                  subtitle: 'Ends in ${daysRemainingInMonth}d',
                  icon: Icons.emoji_events_rounded,
                  accentColor: AppColors.amber500,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // ── 3. Your Personal Invite Code Box ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.slate50,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR INVITE CODE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.5.sp,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        referralCode,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 19.sp,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ],
                  ),
                ),
                ScaleButton(
                  onTap: () {
                    di.sl<HapticService>().selection();
                    onCopy();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isCopied
                          ? AppColors.emerald500.withValues(alpha: 0.15)
                          : AppColors.indigo500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isCopied
                            ? AppColors.emerald500.withValues(alpha: 0.3)
                            : AppColors.indigo500.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCopied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 14.r,
                          color: isCopied
                              ? AppColors.emerald500
                              : AppColors.indigo500,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          isCopied ? 'Copied!' : 'Copy Code',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w900,
                            color: isCopied
                                ? AppColors.emerald500
                                : AppColors.indigo500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ── 4. VIP Benefit Tracker Banner ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: hasActivePremium
                  ? AppColors.amber500.withValues(alpha: 0.10)
                  : AppColors.indigo500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: hasActivePremium
                    ? AppColors.amber500.withValues(alpha: 0.25)
                    : AppColors.indigo500.withValues(alpha: 0.20),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasActivePremium ? Icons.star_rounded : Icons.bolt_rounded,
                  size: 16.r,
                  color: hasActivePremium
                      ? AppColors.amber500
                      : AppColors.indigo500,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    hasActivePremium && premiumExpiryDate != null
                        ? 'VIP Active until ${_formatDate(premiumExpiryDate!)} • Each friend adds +24 Hours'
                        : 'Every friend who finishes Level 1 gives you 24 Hours of full VIP access!',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: hasActivePremium
                          ? (isDark
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFFB45309))
                          : (isDark
                                ? const Color(0xFFA5B4FC)
                                : const Color(0xFF4338CA)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // ── 5. Primary Share Action Button ──
          ScaleButton(
            onTap: () {
              di.sl<HapticService>().light();
              onShare();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 13.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500,
                borderRadius: BorderRadius.circular(14.r),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 16.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Share Invite Link & Card',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 6. Friend's Code Status or Input Trigger ──
          SizedBox(height: 10.h),
          if (hasClaimedReferral) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 15.r,
                    color: AppColors.emerald500,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Welcome bonus claimed (${referredBy ?? 'Ambassador'}) • 100 Coins & VIP Active!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (pendingReferralCode != null &&
              pendingReferralCode!.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 15.r,
                    color: AppColors.amber500,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite "$pendingReferralCode" Saved!',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Finish Level 1 to activate your 100 Coins & 1 Day VIP!',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ScaleButton(
              onTap: () {
                di.sl<HapticService>().selection();
                onEnterCode();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.20),
                    width: 1.0,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.redeem_rounded,
                        size: 15.r,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Were you invited by a friend? Tap to enter code',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBentoPod({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.r, color: accentColor),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.slate900,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
