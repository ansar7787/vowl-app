import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrueFalseReadingInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const TrueFalseReadingInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Icon(
                  Icons.published_with_changes_rounded,
                  size: 14.r,
                  color: primaryColor,
                ),
              ),
            ),
            TextSpan(
              text: instruction?.toUpperCase() ?? "FLICK THE TRUTH COIN TO VALIDATE",
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: primaryColor,
          letterSpacing: 1.2,
          height: 1.4,
        ),
      ),
    );
  }
}
