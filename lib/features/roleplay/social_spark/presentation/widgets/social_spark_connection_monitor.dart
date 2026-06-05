import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SocialSparkConnectionMonitor extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;

  const SocialSparkConnectionMonitor({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    Color outlineColor = color;
    if (isAnswered) {
      outlineColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: outlineColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: outlineColor.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hub_rounded, color: outlineColor, size: 18.r),
              SizedBox(width: 8.w),
              Text(
                isAnswered
                    ? ((isCorrect ?? false) ? "ALIGNMENT STABLE" : "SIGNAL COLLAPSED")
                    : "CONSTELLATION HARMONICS",
                style: TextStyle(fontFamily: 'RobotoMono', 
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: outlineColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                text.isEmpty ? "SELECT INITIAL STAR NODE..." : text,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 20.sp,
                  color: text.isEmpty
                      ? Colors.grey.shade600
                      : (isDark ? Colors.white : Colors.black87),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
