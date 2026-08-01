import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class SummarizeStoryManuscript extends StatelessWidget {
  final String story;
  final Color color;
  final bool isDark;

  const SummarizeStoryManuscript({
    super.key,
    required this.story,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
          Text(
            story,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF334155),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
