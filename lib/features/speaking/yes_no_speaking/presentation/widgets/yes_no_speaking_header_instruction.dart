import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class YesNoSpeakingHeaderInstruction extends StatelessWidget {
  final Color primaryColor;
  final bool isSnapped;

  const YesNoSpeakingHeaderInstruction({
    super.key,
    required this.primaryColor,
    required this.isSnapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edgesensor_high_rounded, size: 12.r, color: primaryColor),
              SizedBox(width: 8.w),
              Text(
                isSnapped ? "NOW SPEAK THE TARGET SENTENCE" : "TILT THE CORE SPHERE TO ALIGN",
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          isSnapped
              ? "Alignment locked! Hold the recording lens and read the target sentence aloud!"
              : "Compare the spoken audio prompt with the written card below and slide to YES or NO!",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
