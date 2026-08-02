import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpeedVarianceInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const SpeedVarianceInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(Icons.speed_rounded, size: 14.r, color: color),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              instruction.trim().isEmpty
                  ? "IDENTIFY THE SPEAKING SPEED"
                  : instruction.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.sp, letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
