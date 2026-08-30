import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AcademicWordFieldCollocations extends StatelessWidget {
  final String? academicField;
  final List<String>? collocations;
  final String? contextSentence;
  final Color color;

  const AcademicWordFieldCollocations({
    super.key,
    this.academicField,
    this.collocations,
    this.contextSentence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (academicField != null) ...[
            Row(
              children: [
                Icon(Icons.school_rounded, color: color, size: 20.r),
                SizedBox(width: 8.w),
                AutoSizeText(
                  "ACADEMIC FIELD: ${academicField!.toUpperCase()}",
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
          
          if (collocations != null && collocations!.isNotEmpty) ...[
            if (academicField != null) SizedBox(height: 12.h),
            Text(
              "Common Collocations:",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : Colors.black54,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: collocations!.map((colloc) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    colloc,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (contextSentence != null) ...[
            if (academicField != null || (collocations != null && collocations!.isNotEmpty)) SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.format_quote_rounded, color: color, size: 20.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    "\"$contextSentence\"",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}
