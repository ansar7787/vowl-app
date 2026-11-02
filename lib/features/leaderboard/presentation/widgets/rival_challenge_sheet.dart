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

    final surfaceColor = isDark ? AppColors.midnightSurface : (tokens?.surface ?? Colors.white);
    final borderColor = isDark ? AppColors.slate800 : (tokens?.border ?? const Color(0xFFE2E8F0));
    final textPrimary = isDark ? Colors.white : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));

    final hasEnoughCoins = currentUser.coins >= 30;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate700 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 18.h),

          // Rival Profile Header
          Row(
            children: [
              UserAvatar(photoUrl: rival.photoUrl, size: 52.r),
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
                    SizedBox(height: 2.h),
                    Text(
                      'Rank #$rivalRank · ${rival.totalExp} XP · ${rival.currentStreak}d Streak',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // Stakes & Rules Card
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStakeColumn('Entry Stake', '30 Coins', AppColors.indigo500, isDark),
                    Icon(LucideIcons.swords, size: 20.sp, color: const Color(0xFFF59E0B)),
                    _buildStakeColumn('Winner Takes', '50 Coins', const Color(0xFF10B981), isDark),
                  ],
                ),
                SizedBox(height: 10.h),
                Divider(color: borderColor, height: 1.h),
                SizedBox(height: 8.h),
                Text(
                  'Consolation prize: 10 Coins to loser · Zero waiting time',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // Start Duel Button
          ElevatedButton.icon(
            onPressed: hasEnoughCoins ? () {
              Navigator.of(context).pop();
              onStartDuel();
            } : null,
            icon: Icon(LucideIcons.swords, size: 18.sp),
            label: Text(
              hasEnoughCoins ? '⚔️ Stake 30 Coins & Duel' : 'Need 30 Coins to Duel',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
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

          SizedBox(height: 8.h),

          // Room Code Button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onShareRoomCode();
            },
            icon: Icon(LucideIcons.share2, size: 16.sp, color: textPrimary),
            label: Text(
              'Share Room Code Challenge',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
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
