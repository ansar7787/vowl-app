import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ClozeTestInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const ClozeTestInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_input_component_rounded,
            size: 14.r,
            color: primaryColor,
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              instruction?.toUpperCase() ??
                  "INJECT FUEL CELLS TO POWER THE PASSAGE",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                height: 1.4,
                letterSpacing: 1.5,
              ),
            ),
          ),
          // Balances the icon on the left to perfectly center the text visually
          SizedBox(width: 14.r + 12.w),
        ],
      ),
    );
  }
}
