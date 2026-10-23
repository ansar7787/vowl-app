import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Anatomical indicator visualizing vocal cord vibration (voicing) and pulmonary airflow dynamics.
class ConsonantClarityThroatIndicator extends StatelessWidget {
  /// Vocal fold vibration classification (e.g., 'voiced' or 'unvoiced').
  final String voicing;

  /// Manner of pulmonary airflow articulation (e.g., 'plosive', 'fricative').
  final String airflow;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [ConsonantClarityThroatIndicator] widget.
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
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget waveIcon = Icon(
      Icons.graphic_eq_rounded,
      color: isVoiced ? color : Colors.grey,
      size: 26.r,
    );

    if (!reduceMotion && isVoiced) {
      waveIcon = waveIcon
          .animate(
            onPlay: (c) {
              c.repeat();
            },
          )
          .shimmer(duration: 1.seconds);
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 340.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.05),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Throat / Vocal Cords Icon
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isVoiced
                  ? color.withValues(alpha: 0.18)
                  : Colors.grey.withValues(alpha: 0.18),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                waveIcon,
                if (!isVoiced)
                  Icon(
                    Icons.do_not_disturb_alt_rounded,
                    color: Colors.grey.withValues(alpha: 0.5),
                    size: 36.r,
                  ),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "VOCAL CORDS",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isVoiced ? "Vibrating (Voiced)" : "Still (Voiceless)",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Airflow: ${airflow.toUpperCase()}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
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
