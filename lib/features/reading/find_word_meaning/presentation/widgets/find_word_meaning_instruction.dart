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
    return Semantics(
      header: true,
      label: instruction ?? 'FIND WORD MEANING',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(Icons.zoom_in_rounded, size: 14.r, color: primaryColor),
            ),
            SizedBox(width: 12.w),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                (instruction ?? 'FIND WORD MEANING').toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
