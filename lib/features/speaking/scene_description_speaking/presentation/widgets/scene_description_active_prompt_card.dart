import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SceneDescriptionActivePromptCard extends StatelessWidget {
  final int activeHotspot;
  final String activePrompt;
  final Color primaryColor;
  final bool isDark;

  const SceneDescriptionActivePromptCard({
    super.key,
    required this.activeHotspot,
    required this.activePrompt,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F0F1A)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.spatial_audio_off_rounded,
                color: primaryColor,
                size: 14.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "DESCRIBE COMPONENT",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            activePrompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
