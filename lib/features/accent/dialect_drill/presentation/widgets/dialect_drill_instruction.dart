import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DialectDrillInstruction extends StatelessWidget {
  final String instruction;
  final Color accentColor;

  const DialectDrillInstruction({
    super.key,
    required this.instruction,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            "REGIONAL DIALECT DRILL",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: 2.5,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          instruction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
