import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PitchPatternMatchInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const PitchPatternMatchInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final text = instruction.trim().isEmpty
        ? "MATCH THE PITCH PATTERN"
        : instruction.toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.graphic_eq_rounded, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: null,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
