import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Clean countdown timer bar with subtle urgency indicator and dynamic bonus time badge.
class TopicFusionTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final Color accentColor;
  final int bonusSecondsAdded;

  const TopicFusionTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.accentColor,
    this.bonusSecondsAdded = 0,
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
          if (isUrgent && !VowlMotion.shouldReduceMotion(context))
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
          if (bonusSecondsAdded > 0) ...[
            SizedBox(width: 6.w),
            _buildBonusBadge(context),
          ],
        ],
      ),
    );
  }

  Widget _buildBonusBadge(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.emerald500,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '+${bonusSecondsAdded}s',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) {
      return badge;
    }

    return badge
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.25, end: 0, duration: 250.ms, curve: Curves.easeOutBack)
        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1));
  }
}
