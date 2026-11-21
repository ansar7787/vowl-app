import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Clean countdown timer bar with subtle urgency indicator.
class TopicFusionTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final Color accentColor;

  const TopicFusionTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (remainingSeconds / (totalSeconds > 0 ? totalSeconds : 30))
        .clamp(0.0, 1.0);

    final isUrgent = remainingSeconds <= 5;
    final timerColor = isUrgent
        ? AppColors.rose500
        : (remainingSeconds <= 10 ? AppColors.amber500 : accentColor);

    final timerIcon = Icon(
      Icons.timer_outlined,
      color: timerColor,
      size: 16.r,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark
            ? (isUrgent
                ? AppColors.rose500.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.04))
            : (isUrgent
                ? AppColors.rose500.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: timerColor.withValues(alpha: isUrgent ? 0.5 : 0.25),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          if (isUrgent)
            timerIcon
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 400.ms)
          else
            timerIcon,
          SizedBox(width: 8.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                minHeight: 6.h,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          AutoSizeText(
            '${remainingSeconds}s',
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: timerColor,
            ),
          ),
        ],
      ),
    );
  }
}
