import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShadowingChallengeInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const ShadowingChallengeInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        instruction.trim().isEmpty
            ? "IDENTIFY THE PRONUNCIATION"
            : instruction.toUpperCase(),
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.0,
          height: 1.35,
        ),
      ),
    );
  }
}
