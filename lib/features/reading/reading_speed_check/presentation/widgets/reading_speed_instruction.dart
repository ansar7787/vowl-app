import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadingSpeedInstruction extends StatelessWidget {
  final Color primaryColor;
  final bool isRevealed;
  final String? instruction;

  const ReadingSpeedInstruction({
    super.key,
    required this.primaryColor,
    required this.isRevealed,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              instruction?.toUpperCase() ??
                  (isRevealed
                      ? "ANALYZE THE COMPREHENSION QUEST"
                      : "TAP THE GLOWING SONIC CORE TO BRIEFLY UNBLUR TEXT"),
              style: TextStyle(
                fontFamily: 'Outfit',
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
