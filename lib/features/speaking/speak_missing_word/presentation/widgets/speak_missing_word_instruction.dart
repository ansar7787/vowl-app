import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class SpeakMissingWordInstruction extends StatelessWidget {
  final Color primaryColor;
  final bool isWordPlaced;

  const SpeakMissingWordInstruction({
    super.key,
    required this.primaryColor,
    required this.isWordPlaced,
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
              Icon(Icons.auto_awesome_rounded, size: 12.r, color: primaryColor),
              SizedBox(width: 8.w),
              Text(
                isWordPlaced ? "READ THE COMPLETED SENTENCE" : "PULL CORRECT WORD INTO VORTEX",
                style: TextStyle(fontFamily: 'Outfit', 
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
          isWordPlaced
              ? "Option aligned! Hold the recording lens and speak the full sentence aloud!"
              : "Examine the sentence layout and hold-pull the fitting vocabulary magnetic card!",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
