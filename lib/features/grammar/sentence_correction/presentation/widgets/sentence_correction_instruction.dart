import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner guiding users to diagnose and correct sentence errors.
class SentenceCorrectionInstruction extends StatelessWidget {
  /// The primary theme accent color.
  final Color primaryColor;

  /// The instruction text describing the objective.
  final String instruction;

  /// Creates a [SentenceCorrectionInstruction] widget.
  const SentenceCorrectionInstruction({
    super.key,
    required this.primaryColor,
    this.instruction = "Sentence Correction",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sentence_correction_instruction'),
      constraints: BoxConstraints(maxWidth: 0.88.sw),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_rounded, size: 16.r, color: primaryColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              instruction,
              key: const ValueKey('sentence_correction_instruction_text'),
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
