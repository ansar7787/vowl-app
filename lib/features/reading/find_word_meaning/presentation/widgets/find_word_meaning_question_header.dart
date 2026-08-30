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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      borderRadius: BorderRadius.circular(20.r),
      color: color.withValues(alpha: isDark ? 0.1 : 0.08),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: color, size: 24.r),
          SizedBox(width: 16.w),
          Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Locate meaning:\n",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? color.withValues(alpha: 0.7) : color.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: text,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }
}
