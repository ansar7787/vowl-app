import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PrepositionChoiceInstruction extends StatelessWidget {
  final Color primaryColor;
  const PrepositionChoiceInstruction({super.key, required this.primaryColor});

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
          Icon(Icons.gesture_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "TRACE THE ENERGY PATH",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
