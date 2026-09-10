import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DirectIndirectSpeechInstruction extends StatelessWidget {
  final Color primaryColor;
  const DirectIndirectSpeechInstruction({
    super.key,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 16.r,
            color: primaryColor,
          ),
          SizedBox(width: 8.w),
          Text(
            "CHOOSE THE REPORTED SPEECH",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
