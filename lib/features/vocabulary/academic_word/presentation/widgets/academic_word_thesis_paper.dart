import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AcademicWordThesisPaper extends StatelessWidget {
  final String passage;
  final Color color;
  final bool isDark;
  final GlobalKey slotKey;
  final bool isAnswered;
  final bool? isCorrect;
  final String? correctAnswer;

  const AcademicWordThesisPaper({
    super.key,
    required this.passage,
    required this.color,
    required this.isDark,
    required this.slotKey,
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final parts = passage.split('[TARGET]');

    return Container(
      width: 330.w,
      padding: EdgeInsets.all(28.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 50,
          ),
        ],
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.crimsonPro(
            fontSize: 20.sp,
            height: 1.6,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          children: [
            TextSpan(text: parts[0]),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                key: slotKey,
                width: 150.w,
                height: 40.h,
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: isAnswered && isCorrect == false ? Colors.red : color,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Center(
                  child: isAnswered && isCorrect == true
                      ? Text(
                          correctAnswer?.toUpperCase() ?? "",
                          style: GoogleFonts.shareTechMono(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ).animate().fadeIn().scale()
                      : Text(
                          "THRUST_PENDING",
                          style: GoogleFonts.shareTechMono(
                            color: color.withValues(alpha: 0.3),
                            fontSize: 10.sp,
                            letterSpacing: 1,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).shimmer(),
                ),
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 1.seconds)
    .slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic);
  }
}
