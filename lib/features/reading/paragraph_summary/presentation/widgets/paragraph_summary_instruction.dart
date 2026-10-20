import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ParagraphSummaryInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const ParagraphSummaryInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final text = (instruction != null && instruction!.trim().isNotEmpty)
        ? instruction!.trim()
        : 'Choose the best summary for the paragraph.';

    return Semantics(
      header: true,
      label: text,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 340.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20.r),
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
                  size: 16.r,
                  color: primaryColor,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    height: 1.35,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
