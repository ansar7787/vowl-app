import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SsFeedbackCard extends StatelessWidget {
  final bool isCorrect;
  final String hint;
  final String word;
  final String correctOption;
  final Color primaryColor;
  final VoidCallback onNext;
  final bool isMidnight;

  const SsFeedbackCard({
    super.key,
    required this.isCorrect,
    required this.hint,
    required this.word,
    required this.correctOption,
    required this.primaryColor,
    required this.onNext,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: (isCorrect ? Colors.green : Colors.red).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 32.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? "PERFECT RHYTHM!" : "NOT QUITE",
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      "Say it like: $correctOption",
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildHintTip(isDark),
          SizedBox(height: 12.h),
          _buildRhythmTip(isDark),
          SizedBox(height: 24.h),
          ScaleButton(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "CONTINUE",
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, curve: Curves.easeOutQuad);
  }

  Widget _buildHintTip(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text("💡", style: TextStyle(fontSize: 24.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "EXPLANATION",
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  hint,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhythmTip(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text("👏", style: TextStyle(fontSize: 24.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "TIP: Clap your hands to the beat. The loudest clap is the stress!",
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
