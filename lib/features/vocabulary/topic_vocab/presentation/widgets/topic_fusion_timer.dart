import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Responsive countdown timer bar with urgent heartbeat pulse for Mastery Phase speed challenge.
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
      size: 18.r,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? (isUrgent
                ? AppColors.rose500.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05))
            : (isUrgent
                ? AppColors.rose500.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: timerColor.withValues(alpha: isUrgent ? 0.6 : 0.3),
          width: isUrgent ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          if (isUrgent)
            timerIcon
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.25, 1.25), duration: 400.ms)
          else
            timerIcon,
          SizedBox(width: 8.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                minHeight: 8.h,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          AutoSizeText(
            '${remainingSeconds}s',
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: timerColor,
            ),
          ),
        ],
      ),
    );
  }
}
