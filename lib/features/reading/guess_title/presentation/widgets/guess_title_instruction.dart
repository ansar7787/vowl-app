import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GuessTitleInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const GuessTitleInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final rawText = (instruction != null && instruction!.trim().isNotEmpty)
        ? instruction!.trim()
        : 'Choose the best title for the passage';
    final displayText = rawText.toUpperCase();

    return Semantics(
      header: true,
      label: rawText,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.auto_stories_rounded,
                size: 15.r,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 8.w),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: 0.8,
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
