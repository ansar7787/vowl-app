import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class MinimalPairsDroneOption extends StatelessWidget {
  final int index;
  final String word;
  final String ipa;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedDroneIndex;
  final Function(int, int) onShoot;

  const MinimalPairsDroneOption({
    super.key,
    required this.index,
    required this.word,
    required this.ipa,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedDroneIndex,
    required this.onShoot,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedDroneIndex == index;
    final bool correct = index == correctIndex;
    
    Color borderColor = color.withValues(alpha: 0.3);
    if (isAnswered && isSelected) {
      borderColor = correct ? Colors.greenAccent : Colors.redAccent;
    } else if (isSelected) {
      borderColor = color;
    }

    return ScaleButton(
      onTap: () => onShoot(index, correctIndex),
      child: Column(
        children: [
          AnimatedContainer(
            duration: 250.milliseconds,
            width: 130.w,
            height: 110.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.black45 : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: (isSelected && isAnswered) 
                    ? (correct ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3))
                    : color.withValues(alpha: isDark ? 0.25 : 0.08), 
                  blurRadius: 10
                )
              ],
            ),
            child: Stack(
              children: [
                const TechPatternOverlay(opacity: 0.05),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        word.toUpperCase(), 
                        style: GoogleFonts.shareTechMono(
                          fontSize: 18.sp, 
                          fontWeight: FontWeight.bold, 
                          color: isDark ? Colors.white : Colors.black87
                        )
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r)
                        ),
                        child: Text(
                          ipa, 
                          style: GoogleFonts.shareTechMono(
                            fontSize: 11.sp, 
                            fontWeight: FontWeight.bold,
                            color: color
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: index == 0 ? 8.h : -8.h, duration: (2 + index).seconds),
          
          if (isAnswered && isSelected) ...[
            SizedBox(height: 10.h),
            Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: correct ? Colors.greenAccent : Colors.redAccent,
              size: 20.r,
            ).animate().scale(),
          ]
        ],
      ),
    );
  }
}
