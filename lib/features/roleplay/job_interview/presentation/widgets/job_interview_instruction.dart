import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Objective instruction card for the Job Interview minigame.
class JobInterviewInstruction extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Custom instruction text or fallback.
  final String? instruction;

  /// Creates a [JobInterviewInstruction] widget.
  const JobInterviewInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('job_interview_instruction_container'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        instruction ??
            "Choose the best answer to show off your professional skills.",
        key: const Key('job_interview_instruction_text'),
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          height: 1.4,
        ),
      ),
    );
  }
}
