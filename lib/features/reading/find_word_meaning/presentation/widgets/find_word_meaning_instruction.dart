import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class FindWordMeaningInstruction extends StatelessWidget {
  final Color primaryColor;

  const FindWordMeaningInstruction({
    super.key,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.zoom_in_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              "SCAN THE MANUSCRIPT WITH THE LEXICAL LENS",
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
