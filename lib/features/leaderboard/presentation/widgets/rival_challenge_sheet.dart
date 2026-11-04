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
  final VoidCallback onStartDuel;
  final VoidCallback onShareRoomCode;

  const RivalChallengeSheet({
    super.key,
    required this.rival,
    required this.rivalRank,
    required this.currentUser,
    required this.onStartDuel,
    required this.onShareRoomCode,
  });

  static Future<void> show({
    required BuildContext context,
    required UserEntity rival,
    required int rivalRank,
    required UserEntity currentUser,
    required VoidCallback onStartDuel,
    required VoidCallback onShareRoomCode,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RivalChallengeSheet(
        rival: rival,
        rivalRank: rivalRank,
        currentUser: currentUser,
        onStartDuel: onStartDuel,
        onShareRoomCode: onShareRoomCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final surfaceColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : (tokens?.surface ?? Colors.white));
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);
    final textPrimary = isDark ? Colors.white : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));

    final hasEnoughCoins = currentUser.coins >= 30;

    // Resilient safe-area clearance for older 3-button navigation, gesture bars & keyboards
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final systemBottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final safeBottom = (systemBottomPadding > 0 ? systemBottomPadding : 24.h) + bottomInset + 12.h;

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
                    color: isDark ? AppColors.slate700 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),

              // Rival Profile Header Card
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        UserAvatar(
                          photoUrl: rival.photoUrl,
                          size: 56.r,
                          border: Border.all(
                            color: AppColors.indigo500.withValues(alpha: 0.6),
                            width: 2.w,
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.indigo500,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '#$rivalRank',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  rival.safeDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              if (rival.isPremium) ...[
                                SizedBox(width: 4.w),
                                Icon(Icons.verified_rounded, size: 16.sp, color: const Color(0xFFF59E0B)),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: [
                              _buildPill(
                                icon: LucideIcons.zap,
                                label: '${rival.totalExp} XP',
                                color: AppColors.indigo500,
                                isDark: isDark,
                              ),
                              _buildPill(
                                icon: LucideIcons.flame,
                                label: '${rival.currentStreak}d streak',
                                color: const Color(0xFFF97316),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Stakes & Match Arena Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.indigo500.withValues(alpha: isDark ? 0.12 : 0.06),
                      AppColors.blue500.withValues(alpha: isDark ? 0.08 : 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _buildStakeColumn('Entry Stake', '30 Coins', const Color(0xFFF59E0B), isDark),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.indigo500.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.swords, size: 20.sp, color: AppColors.indigo500),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _buildStakeColumn('Winner Takes', '50 Coins', const Color(0xFF10B981), isDark),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Divider(color: borderColor, height: 1.h),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 14.sp, color: textSecondary),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Consolation: +10 Coins to runner-up • Instant 60s duel',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // User Balance Pill
              Center(
                child: Text(
                  'Your Balance: ${currentUser.coins} Coins',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: hasEnoughCoins ? (isDark ? AppColors.slate300 : AppColors.slate700) : AppColors.rose500,
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              // Start Duel Button
              ElevatedButton.icon(
                onPressed: hasEnoughCoins ? () {
                  Navigator.of(context).pop();
                  onStartDuel();
                } : null,
                icon: Icon(LucideIcons.swords, size: 18.sp),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hasEnoughCoins ? 'Challenge to 1v1 Arena Duel' : 'Need 30 Coins to Duel',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? AppColors.slate800 : AppColors.slate200,
                  disabledForegroundColor: isDark ? AppColors.slate500 : AppColors.slate400,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
              ),

              SizedBox(height: 8.h),

              // Room Code Button
              OutlinedButton.icon(
                onPressed: hasEnoughCoins ? () {
                  Navigator.of(context).pop();
                  onShareRoomCode();
                } : null,
                icon: Icon(LucideIcons.share2, size: 16.sp, color: hasEnoughCoins ? textPrimary : textSecondary),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Share Room Code Challenge',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: hasEnoughCoins ? textPrimary : textSecondary,
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

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeColumn(String title, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDark ? AppColors.slate400 : const Color(0xFF64748B),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

