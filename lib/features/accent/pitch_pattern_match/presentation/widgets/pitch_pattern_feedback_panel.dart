import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class PitchPatternFeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String correctPattern;
  final String hint;
  final VoidCallback onListenAgain;
  final bool isDark;
  final bool isMidnight;

  const PitchPatternFeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.correctPattern,
    required this.hint,
    required this.onListenAgain,
    required this.isDark,
    this.isMidnight = false,
  });

  IconData _getPatternIcon() {
    final lower = correctPattern.toLowerCase();
    if (lower.contains('rising')) {
      return Icons.trending_up_rounded;
    } else if (lower.contains('falling')) {
      return Icons.trending_down_rounded;
    } else if (lower.contains('flat')) {
      return Icons.trending_flat_rounded;
    }
    return Icons.gesture_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? Colors.greenAccent : Colors.orangeAccent;

    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(30.r),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: color,
                  size: 32.r,
                ).animate().scale(delay: 200.ms),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? "Spot On!" : "Let's Review",
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      "Correct pattern: $correctPattern",
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Enhanced Visual Cue
          Container(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Icon(_getPatternIcon(), size: 64.r, color: color)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .slideX(begin: -0.1, end: 0.1, duration: 1.seconds)
                    .shimmer(delay: 1.seconds, duration: 1.seconds),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          ElevatedButton.icon(
            onPressed: onListenAgain,
            icon: Icon(
              Icons.replay_rounded,
              size: 20.r,
              color: isDark ? Colors.black87 : Colors.white,
            ),
            label: Text(
              "LISTEN AGAIN",
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: isDark ? Colors.black87 : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black87,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
