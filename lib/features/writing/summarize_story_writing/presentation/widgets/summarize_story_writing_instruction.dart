import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner presenting guidelines for story summarization.
class SummarizeStoryWritingInstruction extends StatelessWidget {
  /// Instruction text explaining how to sequence the story summary.
  final String instruction;

  /// The primary theme accent color for borders and icons.
  final Color primaryColor;

  /// Creates a [SummarizeStoryWritingInstruction] widget.
  const SummarizeStoryWritingInstruction({
    super.key,
    required this.instruction,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Instruction: $instruction',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.auto_stories_rounded,
                size: 20.r,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                instruction,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: null,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  letterSpacing: 0.1,
                  color: primaryColor,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Symmetrical balance icon for centered multi-line alignment
            ExcludeSemantics(
              child: Icon(
                Icons.auto_stories_rounded,
                size: 20.r,
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
