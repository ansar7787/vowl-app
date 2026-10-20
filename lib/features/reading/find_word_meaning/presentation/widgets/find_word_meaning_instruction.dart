import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FindWordMeaningInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const FindWordMeaningInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final text = (instruction != null && instruction!.trim().isNotEmpty)
        ? instruction!.trim()
        : 'Find Word Meaning';

    return Semantics(
      header: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.search_rounded,
                size: 15.r,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 8.w),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
