import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VowelDistinctionInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const VowelDistinctionInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  String _cleanInstruction(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return "Slide or tap to match the vowel sound";
    }
    // If incoming text is shouting ALL CAPS, format into natural, human sentence case
    if (trimmed == trimmed.toUpperCase() && trimmed.length > 3) {
      final lower = trimmed.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _cleanInstruction(instruction);

    return Container(
      constraints: BoxConstraints(maxWidth: 340.w),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.35,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
