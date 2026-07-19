import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SyllableStressInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const SyllableStressInstruction({
    super.key,
    required this.color,
    required this.instruction,
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
          Icon(Icons.speaker_group_rounded, size: 14.r, color: color),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              instruction.trim().isEmpty
                  ? "TAP THE STRESSED SYLLABLE"
                  : instruction.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: null,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
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
