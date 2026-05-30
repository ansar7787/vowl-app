import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class CorrectionWritingSentenceCard extends StatelessWidget {
  final String passage;
  final String? selectedCorrection;
  final Color color;
  final bool isDark;

  const CorrectionWritingSentenceCard({
    super.key,
    required this.passage,
    required this.selectedCorrection,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final startIdx = passage.indexOf('[');
    final endIdx = passage.indexOf(']');
    
    if (startIdx == -1 || endIdx == -1) {
      return Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Text(
          passage,
          style: GoogleFonts.spectral(
            fontSize: 16.sp,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.6,
          ),
        ),
      );
    }
    
    final preText = passage.substring(0, startIdx);
    final errorText = passage.substring(startIdx + 1, endIdx);
    final postText = passage.substring(endIdx + 1);

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
          const TechPatternOverlay(opacity: 0.05),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.spectral(
                fontSize: 16.sp,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.6,
                fontWeight: FontWeight.w500
              ),
              children: [
                TextSpan(text: preText),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: AnimatedContainer(
                    duration: 300.milliseconds,
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: selectedCorrection != null 
                        ? Colors.greenAccent.withValues(alpha: 0.1) 
                        : Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: selectedCorrection != null ? Colors.greenAccent : Colors.redAccent,
                        width: 2,
                        style: selectedCorrection != null ? BorderStyle.solid : BorderStyle.none
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedCorrection ?? errorText.toUpperCase(),
                          style: GoogleFonts.shareTechMono(
                            fontSize: 14.sp,
                            color: selectedCorrection != null ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          selectedCorrection != null ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                          size: 14.r,
                          color: selectedCorrection != null ? Colors.greenAccent : Colors.redAccent,
                        )
                      ],
                    ),
                  ),
                ),
                TextSpan(text: postText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
