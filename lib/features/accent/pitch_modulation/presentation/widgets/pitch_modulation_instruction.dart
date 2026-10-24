import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner orienting the learner to pragmatic meaning shifts caused by pitch modulation.
class PitchModulationInstruction extends StatelessWidget {
  /// Theme accent color.
  final Color color;

  /// Raw instruction prompt.
  final String instruction;

  /// Creates a [PitchModulationInstruction] widget.
  const PitchModulationInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = instruction.trim().isEmpty
        ? "Listen and choose the meaning that matches the pitch."
        : instruction.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.record_voice_over_rounded,
            size: 18.r,
            color: color,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : color,
                letterSpacing: 0.2,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
