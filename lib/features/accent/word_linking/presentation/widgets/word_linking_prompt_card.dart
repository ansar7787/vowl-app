import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class WordLinkingPromptCard extends StatelessWidget {
  final Color color;
  final bool isDark;

  const WordLinkingPromptCard({
    super.key,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342.w,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 2),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: TechPatternOverlay(opacity: 0.05),
          ),
          Text(
            "When native speakers talk fast, the end of one word often connects smoothly to the beginning of the next. Can you hear where the words link together?",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }
}
