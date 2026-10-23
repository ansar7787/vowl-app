import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner presenting guidelines for the read and answer exercise.
class ReadAndAnswerInstruction extends StatelessWidget {
  /// The primary theme accent color for borders and icons.
  final Color primaryColor;

  /// Optional fallback instruction text describing the exercise.
  final String? instruction;

  /// Creates a [ReadAndAnswerInstruction] widget.
  const ReadAndAnswerInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = (instruction ?? 'READING PASSAGE').toUpperCase();

    return Semantics(
      header: true,
      label: instruction ?? 'Reading Passage',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.auto_stories_rounded,
                size: 14.r,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 8.w),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                displayText,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
