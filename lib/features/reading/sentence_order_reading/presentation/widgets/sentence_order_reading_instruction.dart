import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SentenceOrderReadingInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const SentenceOrderReadingInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
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
      child: Text(
        instruction?.toUpperCase() ?? "RESTORE THE LOGICAL STRUCTURE",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: primaryColor,
          letterSpacing: 1.2,
          height: 1.4,
        ),
      ),
    );
  }
}
