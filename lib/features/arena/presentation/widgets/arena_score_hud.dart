import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';

class ArenaScoreHud extends StatelessWidget {
  final String myName;
  final String? myPhotoUrl;
  final int myScore;
  final String rivalName;
  final String? rivalPhotoUrl;
  final int rivalScore;
  final int currentQuestionIndex;
  final int totalQuestions;
  final int timeRemaining;
  final bool isDark;

  const ArenaScoreHud({
    super.key,
    required this.myName,
    this.myPhotoUrl,
    required this.myScore,
    required this.rivalName,
    this.rivalPhotoUrl,
    required this.rivalScore,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.timeRemaining,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.midnightSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.slate800 : const Color(0xFFE2E8F0),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Current User
              UserAvatar(photoUrl: myPhotoUrl, size: 36.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '$myScore pts',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.indigo500,
                      ),
                    ),
                  ],
                ),
              ),

              // VS & Timer Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF070A12) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 12.sp,
                      color: timeRemaining <= 3 ? AppColors.rose500 : const Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${timeRemaining}s',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: timeRemaining <= 3 ? AppColors.rose500 : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),

              // Rival
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rivalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '$rivalScore pts',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              UserAvatar(photoUrl: rivalPhotoUrl, size: 36.r),
            ],
          ),

          SizedBox(height: 10.h),

          // Linear timer progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: timeRemaining / 10.0,
              minHeight: 4.h,
              backgroundColor: isDark ? AppColors.slate800 : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                timeRemaining <= 3 ? AppColors.rose500 : AppColors.indigo500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
