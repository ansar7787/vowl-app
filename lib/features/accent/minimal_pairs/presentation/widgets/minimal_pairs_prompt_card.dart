import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class MinimalPairsPromptCard extends StatelessWidget {
  final Color color;
  final bool isDark;

  const MinimalPairsPromptCard({
    super.key,
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
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 2),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: TechPatternOverlay(opacity: 0.05),
          ),
          Text(
            "Phonetic contrasts differentiate pairs of words by just one vital vowel or consonant phoneme. Can you distinguish the precise organic difference?",
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
