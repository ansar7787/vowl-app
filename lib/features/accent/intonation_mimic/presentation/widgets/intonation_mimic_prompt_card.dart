import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class IntonationMimicPromptCard extends StatelessWidget {
  final String word;
  final Color color;
  final bool isDark;

  const IntonationMimicPromptCard({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342.w,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
          Center(
            child: Column(
              children: [
                Text(
                  "TARGET SENTENCE",
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  word,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 1,
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
