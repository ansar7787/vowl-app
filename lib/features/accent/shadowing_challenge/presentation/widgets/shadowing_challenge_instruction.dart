import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner directing auditory shadowing and real-time echo repetition.
class ShadowingChallengeInstruction extends StatelessWidget {
  /// Theme accent color.
  final Color color;

  /// Raw instruction prompt.
  final String instruction;

  /// Creates a [ShadowingChallengeInstruction] widget.
  const ShadowingChallengeInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = instruction.trim().isEmpty
        ? "Listen carefully and shadow the speaker phrase."
        : instruction.trim();

    return Container(
      constraints: BoxConstraints(maxWidth: 360.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
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
          letterSpacing: 0.2,
          height: 1.4,
        ),
      ),
    );
  }
}

