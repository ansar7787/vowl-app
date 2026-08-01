import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class ConnectedSpeechPromptCard extends StatelessWidget {
  final String word;
  final Color color;
  final bool isDark;
  final bool isCompact;

  const ConnectedSpeechPromptCard({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342.w,
      padding: EdgeInsets.all(isCompact ? 16.r : 24.r),
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
                  "TARGET PHRASE",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 8.sp : 10.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: isCompact ? 4.h : 8.h),
                Text(
                  word.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 22.sp : 28.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 4,
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
