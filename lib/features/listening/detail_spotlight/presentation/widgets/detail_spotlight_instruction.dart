import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DetailSpotlightInstruction extends StatelessWidget {
  final bool isAnswered;
  final Color color;
  final String instruction;

  const DetailSpotlightInstruction({
    super.key,
    required this.isAnswered,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 340.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.flashlight_on_rounded, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              instruction,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.35,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
