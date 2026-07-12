import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpeakOppositeHeader extends StatelessWidget {
  final String? instruction;
  const SpeakOppositeHeader({super.key, this.instruction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swap_vertical_circle_rounded,
            size: 14.r,
            color: Colors.redAccent,
          ),
          SizedBox(width: 8.w),
          Text(
            instruction?.toUpperCase() ?? "POLAR ELECTROMAGNETIC CONDUIT",
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
