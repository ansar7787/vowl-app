import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ReadAndAnswerAnchorPoint extends StatelessWidget {
  final String question;
  final Color color;
  final bool isDark;

  const ReadAndAnswerAnchorPoint({
    super.key,
    required this.question,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.anchor_rounded, color: color, size: 48.r),
        SizedBox(height: 16.h),
        Text(
          question, 
          textAlign: TextAlign.center, 
          style: GoogleFonts.outfit(
            fontSize: 24.sp, 
            fontWeight: FontWeight.w900, 
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
