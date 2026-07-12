import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class MinimalPairsPromptCard extends StatelessWidget {
  final Color color;
  final bool isDark;
  final String? vowelTensionRule;

  const MinimalPairsPromptCard({
    super.key,
    required this.color,
    required this.isDark,
    this.vowelTensionRule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342.w,
      padding: EdgeInsets.all(20.r),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "These words sound almost exactly the same except for one small sound. Can you hear the difference?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (vowelTensionRule != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.waves, color: color, size: 18.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          vowelTensionRule!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
