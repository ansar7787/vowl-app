import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class JobInterviewInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;
  const JobInterviewInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        instruction ??
            "Choose the best answer to show off your professional skills.",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
    );
  }
}
