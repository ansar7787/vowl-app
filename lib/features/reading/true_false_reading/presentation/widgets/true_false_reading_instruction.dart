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
    final text = (instruction != null && instruction!.trim().isNotEmpty)
        ? instruction!.toUpperCase()
        : 'READ AND DECIDE TRUE OR FALSE';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fact_check_outlined,
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
                letterSpacing: 0.8,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
