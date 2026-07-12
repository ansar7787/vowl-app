import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FixTheSentenceInstruction extends StatelessWidget {
  final bool isWiped;
  final Color primaryColor;

  const FixTheSentenceInstruction({
    super.key,
    required this.isWiped,
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
          Icon(Icons.auto_fix_normal_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            isWiped
                ? "SELECT THE CORRECT REPLACEMENT WORD"
                : "SCRUB AWAY THE LOGICAL DECAY",
            style: TextStyle(
              fontFamily: 'Outfit',
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
