import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpeakOppositeNegativePolePanel extends StatelessWidget {
  final double pullProgress;
  final bool isDark;

  const SpeakOppositeNegativePolePanel({
    super.key,
    required this.pullProgress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool charged = pullProgress > 0.95;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: charged
            ? Colors.cyanAccent.withValues(alpha: 0.15)
            : (isDark
                  ? const Color(0xFF131326)
                  : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: charged
              ? Colors.cyanAccent
              : Colors.cyanAccent.withValues(alpha: 0.25),
          width: 1.5.r,
        ),
        boxShadow: charged
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  blurRadius: 15.r,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.remove_circle_rounded,
            color: charged
                ? Colors.cyanAccent
                : Colors.cyanAccent.withValues(alpha: 0.6),
            size: 16.r,
          ),
          SizedBox(width: 10.w),
          Text(
            charged ? "POLAR FUSION SECURED!" : "NEGATIVE POLE ANTIPODE",
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: charged ? Colors.cyanAccent : Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
