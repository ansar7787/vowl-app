import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';

class DailyExpressionUsagePanel extends StatelessWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;

  const DailyExpressionUsagePanel({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.format_quote_rounded, color: Colors.amberAccent, size: 16.r),
              SizedBox(width: 8.w),
              Text(
                "CONTEXTUAL SAMPLE USAGE",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            "\"${quest.sampleUsage ?? 'Sample usage'}\"",
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 16.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
