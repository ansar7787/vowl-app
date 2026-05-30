import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DailyJournalBoosterTokens extends StatelessWidget {
  final List<String> keywords;
  final String text;
  final Color color;
  final bool isDark;

  const DailyJournalBoosterTokens({
    super.key,
    required this.keywords,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "REQUIRED REFLECTION TERMS (USE AT LEAST 2)",
          style: GoogleFonts.shareTechMono(
            fontSize: 10.sp, 
            color: isDark ? Colors.white54 : Colors.black54, 
            fontWeight: FontWeight.bold
          )
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w, 
          runSpacing: 8.h,
          alignment: WrapAlignment.center,
          children: keywords.map((k) {
            final bool isUsed = text.contains(k.toLowerCase());
            final displayColor = isUsed ? Colors.greenAccent : (isDark ? Colors.white24 : Colors.black26);
            
            return AnimatedContainer(
              duration: 300.milliseconds,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isUsed ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: displayColor, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUsed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 14.r,
                    color: isUsed ? Colors.greenAccent : (isDark ? Colors.white30 : Colors.black38),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    k.toUpperCase(),
                    style: GoogleFonts.shareTechMono(
                      color: isUsed ? Colors.greenAccent : (isDark ? Colors.white60 : Colors.black54),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
