import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadingInferenceInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const ReadingInferenceInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final displayText =
        (instruction ?? 'Read the passage and select the correct inference')
            .toUpperCase();

    return Semantics(
      header: true,
      label: instruction ?? 'Read the passage and select the correct inference',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 14.r,
              color: primaryColor,
            ),
            SizedBox(width: 8.w),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                displayText,
                softWrap: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
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
