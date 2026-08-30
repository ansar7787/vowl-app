import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class FindWordMeaningQuestionHeader extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const FindWordMeaningQuestionHeader({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      borderRadius: BorderRadius.circular(20.r),
      // Neutral glass tile
      color: null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_outline_rounded, color: color, size: 20.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TARGET MEANING",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                    height: 1.4,
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
