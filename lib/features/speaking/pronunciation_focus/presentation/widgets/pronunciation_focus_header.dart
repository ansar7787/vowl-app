import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class PronunciationFocusHeader extends StatelessWidget {
  final Color primaryColor;
  final String instruction;

  const PronunciationFocusHeader({
    super.key,
    required this.primaryColor,
    required this.instruction,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.whatshot_rounded, size: 14.r, color: Colors.orangeAccent),
              SizedBox(width: 8.w),
              Text(
                "THERMOGRAPHIC ACCENT CALIBRATOR",
                style: TextStyle(fontFamily: 'RobotoMono', 
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          instruction,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
