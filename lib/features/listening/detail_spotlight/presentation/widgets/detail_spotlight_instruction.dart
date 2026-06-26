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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flashlight_on_rounded, size: 14.r, color: color),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              instruction.toUpperCase(),
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
