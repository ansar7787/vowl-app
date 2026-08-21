import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class PhrasalVerbsLiteralComparison extends StatelessWidget {
  final String literalVsFigurative;
  final Color color;

  const PhrasalVerbsLiteralComparison({
    super.key,
    required this.literalVsFigurative,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Split the literal vs figurative text. Format expected: "Literal: ... \nFigurative: ..."
    final parts = literalVsFigurative.split('\n');
    final literalText = parts.isNotEmpty ? parts[0] : literalVsFigurative;
    final figurativeText = parts.length > 1 ? parts.sublist(1).join('\n') : "";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: color, size: 20.r),
              SizedBox(width: 8.w),
              AutoSizeText(
                "LITERAL VS FIGURATIVE",
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildComparisonRow("LITERAL", literalText.replaceFirst('Literal: ', ''), isDark, Colors.blueGrey),
          SizedBox(height: 8.h),
          _buildComparisonRow("FIGURATIVE", figurativeText.replaceFirst('Figurative: ', ''), isDark, color),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }

  Widget _buildComparisonRow(String label, String text, bool isDark, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 85.w,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: AutoSizeText(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 9.sp,
                fontWeight: FontWeight.w900,
                color: accentColor,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
