import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class MinimalPairsInstruction extends StatelessWidget {
  final Color color;
  final String? instruction;

  const MinimalPairsInstruction({
    super.key,
    required this.color,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hearing_rounded, size: 14.r, color: color),
          SizedBox(width: 12.w),
          Text(
            instruction?.toUpperCase() ?? "LISTEN AND CHOOSE THE MATCHING WORD",
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
