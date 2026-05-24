import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class FlashcardSwipeBack extends StatelessWidget {
  final dynamic quest;
  final Color color;
  final bool isDark;
  final double width;
  final double height;
  final bool isHintActive;

  const FlashcardSwipeBack({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.width,
    required this.height,
    required this.isHintActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10.h),
            Text(
              "DEFINITION",
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              quest.definition ?? "",
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 19.sp,
                color: isHintActive ? color : (isDark ? Colors.white : Colors.black87),
                height: 1.4,
                fontWeight: isHintActive ? FontWeight.w900 : FontWeight.w500,
                shadows: isHintActive ? [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)] : null,
              ),
            ),
            SizedBox(height: 28.h),
            Divider(
              color: color.withValues(alpha: 0.1),
              thickness: 1,
              indent: 40.w,
              endIndent: 40.w,
            ),
            SizedBox(height: 24.h),
            Text(
              "EXAMPLE",
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                color: Colors.amber.shade700,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              quest.example ?? "",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                color: isDark ? Colors.white70 : Colors.black54,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            if (quest.explanation != null && quest.explanation!.isNotEmpty) ...[
              SizedBox(height: 24.h),
              Text(
                "EXPLANATION",
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white60 : Colors.black45,
                  height: 1.5,
                ),
              ),
            ],
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}
