import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicVocabBanner extends StatelessWidget {
  final String emoji;
  final String topic;
  final Color primaryColor;

  const TopicVocabBanner({
    super.key,
    required this.emoji,
    required this.topic,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 22.sp)),
          SizedBox(width: 10.w),
          Text(
            topic.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: primaryColor,
            ),
          ),
          SizedBox(width: 8.w),
          Icon(Icons.verified_rounded, color: primaryColor, size: 16.r),
        ],
      ),
    ).animate().fadeIn().scale(curve: Curves.easeOutBack);
  }
}
