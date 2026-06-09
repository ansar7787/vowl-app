import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class ShadowingChallengePromptCard extends StatelessWidget {
  final String word;
  final String ipa;
  final Color color;
  final bool isDark;

  const ShadowingChallengePromptCard({
    super.key,
    required this.word,
    required this.ipa,
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
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 2),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: TechPatternOverlay(opacity: 0.05),
          ),
          Center(
            child: Column(
              children: [
                Text(
                  "SHADOW TARGET", 
                  style: TextStyle(fontFamily: 'RobotoMono', 
                    fontSize: 10.sp, 
                    fontWeight: FontWeight.bold, 
                    color: color, 
                    letterSpacing: 2
                  )
                ),
                SizedBox(height: 8.h),
                Text(
                  word, 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 22.sp, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white : Colors.black87, 
                    letterSpacing: 1
                  )
                ),
                if (ipa.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      ipa,
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
