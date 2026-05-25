import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ReadingSpeedQuestionArea extends StatelessWidget {
  final String question;
  final Color color;
  final bool isDark;

  const ReadingSpeedQuestionArea({
    super.key,
    required this.question,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.query_stats_rounded, color: color, size: 48.r),
        SizedBox(height: 16.h),
        Text(
          question, 
          textAlign: TextAlign.center, 
          style: GoogleFonts.outfit(
            fontSize: 22.sp, 
            fontWeight: FontWeight.w900, 
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
