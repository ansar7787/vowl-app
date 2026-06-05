import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class SceneDescriptionHeader extends StatelessWidget {
  final Color primaryColor;

  const SceneDescriptionHeader({
    super.key,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gps_fixed_rounded, size: 14.r, color: Colors.cyanAccent),
          SizedBox(width: 8.w),
          Text(
            "SCENIC SONAR BEACON MAP",
            style: TextStyle(fontFamily: 'RobotoMono', 
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
