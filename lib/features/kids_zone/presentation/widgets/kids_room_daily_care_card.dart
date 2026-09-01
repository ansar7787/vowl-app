import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class KidsRoomDailyCareCard extends StatelessWidget {
  final UserEntity user;
  final bool hasPlayed;
  final bool hasCleaned;
  final bool isClaimed;
  final VoidCallback onClaim;

  const KidsRoomDailyCareCard({ 
    super.key,
    required this.user,
    required this.hasPlayed,
    required this.hasCleaned,
    required this.isClaimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final hasFed =
        user.kidsLastFeedTime != null &&
        user.kidsLastFeedTime!.year == now.year &&
        user.kidsLastFeedTime!.month == now.month &&
        user.kidsLastFeedTime!.day == now.day;

    final allDone = hasFed && hasPlayed && hasCleaned;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: isDark ? 0.4 : 0.6,
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.8),
              width: 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                blurRadius: 10,
                spreadRadius: -2,
                offset: const Offset(0, -2),
              ),
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.2),
                blurRadius: 20,
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
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.amber.shade700,
                    size: 24.sp,
                  ),
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
              if (isClaimed) ...[
                SizedBox(height: 12.h),
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.green.shade500.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.green.shade500),
                    ),
                    child: Text(
                      "Claimed ✅ Come back tomorrow!",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                _buildTaskItem("Feed Buddy", hasFed, isDark),
                SizedBox(height: 8.h),
                _buildTaskItem("Play Game", hasPlayed, isDark),
                SizedBox(height: 8.h),
                _buildTaskItem("Clean Room", hasCleaned, isDark),

                if (allDone) ...[
                  SizedBox(height: 16.h),
                  Center(
                    child:
                        ScaleButton(
                              onTap: onClaim,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 8.h,
                                ),
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
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1.05, 1.05),
                              duration: 1.seconds,
                            ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(String label, bool isDone, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: isDone ? Colors.greenAccent.shade400 : Colors.grey.shade400,
          size: 20.sp,
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
            color: isDone
                ? (isDark ? Colors.greenAccent.shade100 : Colors.green.shade800)
                : (isDark ? Colors.white60 : Colors.black54),
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationColor: isDone ? Colors.greenAccent.shade400 : null,
            decorationThickness: 2,
          ),
        ),
      ],
    );
  }
}
