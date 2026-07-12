import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SceneDescriptionExplorerGuideCard extends StatelessWidget {
  final bool isDark;

  const SceneDescriptionExplorerGuideCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF131326)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.grey, size: 16.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "TAP ANY OF THE PULSING SONAR HOTSPOTS ON THE SCENE CARD ABOVE TO INSPECT AND RECORD YOUR DESCRIPTION.",
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 9.sp,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
