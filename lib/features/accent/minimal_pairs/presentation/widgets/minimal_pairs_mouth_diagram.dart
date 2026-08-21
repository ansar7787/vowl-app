import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MinimalPairsMouthDiagram extends StatelessWidget {
  final String? mouthPosition;
  final Color color;
  final bool isDark;

  const MinimalPairsMouthDiagram({
    super.key,
    required this.mouthPosition,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (mouthPosition == null || mouthPosition!.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.face_retouching_natural_rounded,
              color: color,
              size: 28.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MOUTH & TONGUE",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  mouthPosition!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
