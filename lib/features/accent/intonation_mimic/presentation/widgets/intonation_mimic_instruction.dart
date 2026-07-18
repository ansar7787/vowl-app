import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IntonationMimicInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const IntonationMimicInstruction({
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waves_rounded, size: 14.r, color: color),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              instruction.trim().isEmpty
                  ? "IDENTIFY THE INTONATION"
                  : instruction.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: null,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 8.sp,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
