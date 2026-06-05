import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class ShortAnswerQuillPrompt extends StatelessWidget {
  final String prompt;
  final Color color;
  final bool isDark;

  const ShortAnswerQuillPrompt({
    super.key,
    required this.prompt,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Column(
            children: [
              Icon(Icons.auto_stories_rounded, color: color, size: 32.r)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -5, end: 5),
              SizedBox(height: 16.h),
              Text(
                prompt, 
                style: TextStyle(fontFamily: 'Spectral', 
                  fontSize: 18.sp, 
                  fontWeight: FontWeight.w600, 
                  color: isDark ? Colors.white70 : Colors.black87, 
                  height: 1.6
                ), 
                textAlign: TextAlign.center
              ),
            ],
          ),
        ],
      ),
    );
  }
}
