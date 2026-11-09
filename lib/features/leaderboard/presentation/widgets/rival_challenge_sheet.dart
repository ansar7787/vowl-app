import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class RivalChallengeSheet extends StatelessWidget {
  final UserEntity rival;
  final int rivalRank;
  final UserEntity currentUser;
  final int? currentUserRank;
  final bool isWeekly;
  final VoidCallback onStartDuel;
  final VoidCallback onShareChallenge;

  const RivalChallengeSheet({
    super.key,
    required this.rival,
    required this.rivalRank,
    required this.currentUser,
    this.currentUserRank,
    this.isWeekly = true,
    required this.onStartDuel,
    VoidCallback? onShareChallenge,
    VoidCallback? onShareRoomCode,
  }) : onShareChallenge = onShareChallenge ?? onShareRoomCode ?? _defaultNoop;

  static void _defaultNoop() {}

  static Future<void> show({
    required BuildContext context,
    required UserEntity rival,
    required int rivalRank,
    required UserEntity currentUser,
    int? currentUserRank,
    bool isWeekly = true,
    required VoidCallback onStartDuel,
    VoidCallback? onShareChallenge,
    VoidCallback? onShareRoomCode,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RivalChallengeSheet(
        rival: rival,
        rivalRank: rivalRank,
        currentUser: currentUser,
        currentUserRank: currentUserRank,
        isWeekly: isWeekly,
        onStartDuel: onStartDuel,
        onShareChallenge: onShareChallenge,
        onShareRoomCode: onShareRoomCode,
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
    final cardBgColor = isMidnight
        ? const Color(0xFF0F1523)
        : (isDark ? const Color(0xFF1A2338) : const Color(0xFFF8FAFC));
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);
    final textPrimary = isDark
        ? Colors.white
        : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark
        ? AppColors.slate400
        : (tokens?.textSecondary ?? const Color(0xFF64748B));

    // Resilient safe-area clearance for older 3-button navigation, gesture bars & keyboards
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final systemBottomPadding = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    // Guarantees at least 20dp cushion above ANY system navigation bar or gesture pill
    final safeBottom =
        (systemBottomPadding > 0 ? systemBottomPadding : 16.h) +
        20.h +
        bottomInset;

    final myXp = isWeekly ? currentUser.currentWeeklyExp : currentUser.totalExp;
    final rivalXp = isWeekly ? rival.currentWeeklyExp : rival.totalExp;
    final xpDiff = (rivalXp - myXp).abs();

    final totalXpCombined = math.max(myXp + rivalXp, 1);
    final myRatio = (myXp / totalXpCombined).clamp(0.10, 0.90);

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, safeBottom),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.slate700
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Authentic Head-to-Head Confrontation & Stats Card
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title and XP gap badge (Safe with Expanded)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Head-to-Head Comparison',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            rivalXp >= myXp
                                ? '+$xpDiff XP Gap'
                                : '$xpDiff XP Ahead',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.indigo500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // Side-by-side Player confrontation banner (YOU vs RIVAL)
                    Row(
                      children: [
                        // Left Player: Current User (YOU)
                        Expanded(
                          child: Row(
                            children: [
                              UserAvatar(
                                photoUrl: currentUser.photoUrl,
                                size: 36.r,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            currentUser.safeDisplayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w800,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4.w,
                                            vertical: 1.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.indigo500
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4.r,
                                            ),
                                          ),
                                          child: Text(
                                            'YOU',
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 7.5.sp,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.indigo500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      currentUserRank != null
                                          ? 'Rank #$currentUserRank'
                                          : 'Contender',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
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
                        ),

                        // Center: VS Pill (Solid brand primary, zero AI gradients)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.indigo500,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),

                        // Right Player: Rival
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (rival.isPremium) ...[
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 13.sp,
                                            color: const Color(0xFFF59E0B),
                                          ),
                                          SizedBox(width: 3.w),
                                        ],
                                        Flexible(
                                          child: Text(
                                            rival.safeDisplayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w800,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Rank #$rivalRank',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              UserAvatar(photoUrl: rival.photoUrl, size: 36.r),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),
                    Container(height: 1, color: borderColor),
                    SizedBox(height: 12.h),

                    // Metrics Comparison Rows
                    _buildCompareRow(
                      label: isWeekly ? 'Weekly XP' : 'Lifetime XP',
                      myValue: '$myXp',
                      rivalValue: '$rivalXp',
                      isWinner: myXp >= rivalXp,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    SizedBox(height: 9.h),
                    _buildCompareRow(
                      label: 'Day Streak',
                      myValue: '${currentUser.currentStreak}d',
                      rivalValue: '${rival.currentStreak}d',
                      isWinner:
                          currentUser.currentStreak >= rival.currentStreak,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    SizedBox(height: 9.h),
                    _buildCompareRow(
                      label: 'Quests Completed',
                      myValue: '${currentUser.totalLevelsCompleted}',
                      rivalValue: '${rival.totalLevelsCompleted}',
                      isWinner:
                          currentUser.totalLevelsCompleted >=
                          rival.totalLevelsCompleted,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),

                    SizedBox(height: 14.h),

                    // Visual XP Duel Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.r),
                      child: SizedBox(
                        height: 4.h,
                        child: Row(
                          children: [
                            Expanded(
                              flex: (myRatio * 100).toInt(),
                              child: Container(color: AppColors.indigo500),
                            ),
                            Container(width: 1.5.w, color: surfaceColor),
                            Expanded(
                              flex: ((1.0 - myRatio) * 100).toInt(),
                              child: Container(color: const Color(0xFFF59E0B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 18.h),

              // Action Button 1: Sprint Quests to Overtake (Single vector zap icon, zero duplicate thunder emoji)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onStartDuel();
                },
                icon: Icon(LucideIcons.zap, size: 18.sp),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Sprint Quests to Overtake',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
              ),

              SizedBox(height: 8.h),

              // Action Button 2: Share Challenge Card (Uses our official Share Card modal, zero match codes)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onShareChallenge();
                },
                icon: Icon(LucideIcons.share2, size: 16.sp, color: textPrimary),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Share Challenge Card',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompareRow({
    required String label,
    required String myValue,
    required String rivalValue,
    required bool isWinner,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      children: [
        // Current User Value (Left Column)
        Expanded(
          child: Text(
            myValue,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: isWinner ? AppColors.emerald500 : textPrimary,
            ),
          ),
        ),
        // Metric Label (Center Column)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ),
        // Rival Value (Right Column)
        Expanded(
          child: Text(
            rivalValue,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: !isWinner ? AppColors.indigo500 : textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
