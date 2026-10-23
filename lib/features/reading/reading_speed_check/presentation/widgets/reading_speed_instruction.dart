import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction header displaying gameplay rules dynamically adapting for speed reading versus questions.
class ReadingSpeedInstruction extends StatelessWidget {
  /// The primary theme accent color for borders and icons.
  final Color primaryColor;

  /// Whether the timed passage has concluded and comprehension questions are revealed.
  final bool isRevealed;

  /// Optional fallback instruction text describing the exercise.
  final String? instruction;

  /// Creates a [ReadingSpeedInstruction] widget.
  const ReadingSpeedInstruction({
    super.key,
    required this.primaryColor,
    required this.isRevealed,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final text = isRevealed
        ? "ANSWER THE QUESTION"
        : ((instruction != null && instruction!.trim().isNotEmpty)
            ? instruction!.trim().toUpperCase()
            : "READ QUICKLY AND TAP STOP WHEN DONE");

    return Semantics(
      header: true,
      label: text,
      child: Container(
        constraints: BoxConstraints(maxWidth: 340.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isRevealed ? Icons.help_outline_rounded : Icons.speed_rounded,
              size: 15.r,
              color: primaryColor,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.6,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

