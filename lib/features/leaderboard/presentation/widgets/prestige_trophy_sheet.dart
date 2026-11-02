import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class PrestigeTrophySheet extends StatelessWidget {
  final UserEntity user;
  final int rank;
  final VoidCallback onShareRank;

  const PrestigeTrophySheet({
    super.key,
    required this.user,
    required this.rank,
    required this.onShareRank,
  });

  static Future<void> show({
    required BuildContext context,
    required UserEntity user,
    required int rank,
    required VoidCallback onShareRank,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrestigeTrophySheet(
        user: user,
        rank: rank,
        onShareRank: onShareRank,
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

          // Trophy & Rank Header
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    UserAvatar(photoUrl: user.photoUrl, size: 60.r),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  user.safeDisplayName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Global League Standings',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Stats Bento Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total XP', '${user.totalExp}', LucideIcons.zap, AppColors.indigo500, isDark, borderColor, textPrimary, textSecondary),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildStatItem('Streak', '${user.currentStreak} Days', LucideIcons.flame, const Color(0xFFF59E0B), isDark, borderColor, textPrimary, textSecondary),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildStatItem('Levels', '${user.totalLevelsCompleted}', LucideIcons.award, const Color(0xFF10B981), isDark, borderColor, textPrimary, textSecondary),
              ),
            ],
          ),

          SizedBox(height: 22.h),

          // Share Rank Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onShareRank();
            },
            icon: Icon(LucideIcons.share2, size: 18.sp),
            label: Text(
              '🏆 Share My Rank',
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
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

