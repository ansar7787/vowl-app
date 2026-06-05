import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class DescribeSituationPromptCard extends StatelessWidget {
  final String prompt;
  final Color color;
  final bool isDark;

  const DescribeSituationPromptCard({
    super.key,
    required this.prompt,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SITUATION PROMPT",
                style: TextStyle(fontFamily: 'RobotoMono', 
                  fontSize: 11.sp, 
                  color: color, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1.5
                )
              ),
              SizedBox(height: 8.h),
              Text(
                prompt,
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 16.sp, 
                  color: isDark ? Colors.white70 : Colors.black87, 
                  fontWeight: FontWeight.bold, 
                  height: 1.4
                )
              ),
            ],
          ),
        ],
      ),
    );
  }
}
