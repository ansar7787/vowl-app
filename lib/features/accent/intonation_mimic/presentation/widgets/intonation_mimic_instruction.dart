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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String text = instruction.trim().isEmpty
        ? "Listen and identify the intonation pattern."
        : instruction.trim();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 400.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1.2,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        maxLines: null,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : color,
          letterSpacing: 0.2,
          height: 1.35,
        ),
      ),
    );
  }
}
