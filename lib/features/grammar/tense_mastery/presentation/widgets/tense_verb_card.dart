import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class TenseVerbCard extends StatelessWidget {
  final String verbForm;
  final String? tenseName;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;

  const TenseVerbCard({
    super.key,
    required this.verbForm,
    this.tenseName,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? cardColor;
    Color borderColor = primaryColor.withValues(alpha: 0.1);

    if (showResult) {
      if (isCorrect) {
        cardColor = const Color(0xFF10B981);
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.5);
      } else if (isSelected) {
        cardColor = const Color(0xFFF43F5E);
        borderColor = const Color(0xFFF43F5E).withValues(alpha: 0.5);
      }
    } else if (isSelected) {
      cardColor = primaryColor.withValues(alpha: 0.2);
      borderColor = primaryColor;
    }

    return ScaleButton(
      onTap: showResult ? null : onTap,
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        borderRadius: BorderRadius.circular(24.r),
        color: cardColor?.withValues(alpha: isMidnight ? 0.3 : 0.8),
        borderColor: isMidnight && !isSelected && !showResult 
            ? primaryColor.withValues(alpha: 0.2) 
            : borderColor,
        child: Column(
          children: [
            Text(
              verbForm,
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: (isSelected || (showResult && isCorrect))
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            if (tenseName != null) ...[
              SizedBox(height: 4.h),
              Text(
                tenseName!,
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: (isSelected || (showResult && isCorrect))
                      ? Colors.white.withValues(alpha: 0.7)
                      : (isDark ? Colors.white38 : Colors.black45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
