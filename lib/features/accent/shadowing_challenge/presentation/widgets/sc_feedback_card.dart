import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class SCFeedbackCard extends StatelessWidget {
  final bool isDark;
  final ThemeResult theme;
  final bool isCorrect;
  final bool isLastQuestion;
  final bool isMidnight;

  const SCFeedbackCard({
    super.key,
    required this.isDark,
    required this.theme,
    required this.isCorrect,
    this.isLastQuestion = false,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color feedbackColor = isCorrect ? Colors.green : Colors.orange;
    final String title = isCorrect ? "Great rhythm!" : "Almost there!";
    final String subtitle = isCorrect
        ? "You captured the flow of the sentence."
        : "The timing was a bit off. Try one more time!";
    final IconData icon = isCorrect
        ? Icons.check_circle_rounded
        : Icons.refresh_rounded;

    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(30.r),
      borderColor: feedbackColor.withValues(alpha: 0.3),
      child: Column(
        children: [
          Icon(icon, color: feedbackColor, size: 64.r)
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack)
              .shake(hz: 3, delay: 400.ms),
          SizedBox(height: 16.h),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: feedbackColor,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          if (!isCorrect) ...[
            SizedBox(height: 20.h),
            Text(
              "HOLD MIC TO RETRY",
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: feedbackColor.withValues(alpha: 0.7),
                letterSpacing: 1.5,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
          ],
          if (isLastQuestion && isCorrect) ...[
            SizedBox(height: 24.h),
            Text(
                  "Preparing rewards...",
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1500.ms),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}
