import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TravelDeskInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const TravelDeskInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            "CUSTOMS BIOMETRIC OFFICE",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 2.5,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          instruction ??
              "Drag the mechanical visa stamp onto the matching destination page",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
