import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class KidsRoomDailyCareCard extends StatelessWidget {
  final UserEntity user;
  final bool hasPlayed;
  final bool hasCleaned;
  final VoidCallback onClaim;

  const KidsRoomDailyCareCard({
    super.key,
    required this.user,
    required this.hasPlayed,
    required this.hasCleaned,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if tasks are done
    final now = DateTime.now();
    final hasFed = user.kidsLastFeedTime != null &&
        user.kidsLastFeedTime!.year == now.year &&
        user.kidsLastFeedTime!.month == now.month &&
        user.kidsLastFeedTime!.day == now.day;
    
    final allDone = hasFed && hasPlayed && hasCleaned;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.amber, width: 3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade700,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.amber.shade700, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                "DAILY CARE",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber.shade700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTaskItem("Feed Buddy", hasFed),
          SizedBox(height: 8.h),
          _buildTaskItem("Play Game", hasPlayed),
          SizedBox(height: 8.h),
          _buildTaskItem("Clean Room", hasCleaned),
          
          if (allDone) ...[
            SizedBox(height: 16.h),
            Center(
              child: ScaleButton(
                onTap: onClaim,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade700,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Text(
                    "CLAIM 25 ⭐",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 1.seconds,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTaskItem(String label, bool isDone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: isDone ? Colors.green : Colors.grey.shade400,
          size: 20.sp,
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
            color: isDone ? Colors.green.shade700 : Colors.grey.shade600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationThickness: 2,
          ),
        ),
      ],
    );
  }
}
