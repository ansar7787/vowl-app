import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConsonantClarityThroatIndicator extends StatelessWidget {
  final String voicing;
  final String airflow;
  final Color color;
  final bool isDark;

  const ConsonantClarityThroatIndicator({
    super.key,
    required this.voicing,
    required this.airflow,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool isVoiced = voicing.toLowerCase() == 'voiced';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Throat / Vocal Cords Icon
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isVoiced ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  color: isVoiced ? color : Colors.grey,
                  size: 28.r,
                ).animate(
                  onPlay: (c) {
                    if (isVoiced) c.repeat();
                  },
                ).shimmer(duration: 1.seconds),
                if (!isVoiced)
                  Icon(
                    Icons.do_not_disturb_alt_rounded,
                    color: Colors.grey.withValues(alpha: 0.5),
                    size: 40.r,
                  ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "VOCAL CORDS",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isVoiced ? "Vibrating (Voiced)" : "Still (Voiceless)",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Airflow: ${airflow.toUpperCase()}",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.sp,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
    );
  }
}
