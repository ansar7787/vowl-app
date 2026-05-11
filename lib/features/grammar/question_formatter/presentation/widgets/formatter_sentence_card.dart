import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class FormatterSentenceCard extends StatelessWidget {
  final String sentence;
  final String instruction;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;
  final Widget? badge;

  const FormatterSentenceCard({
    super.key,
    required this.sentence,
    required this.instruction,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    return GlassTile(
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(32.r),
      borderColor: primaryColor.withValues(alpha: isMidnight ? 0.1 : 0.3),
      color: isMidnight
          ? Colors.black.withValues(alpha: 0.2)
          : (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  instruction.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: primaryColor,
                  ),
                ),
              ),
              ?badge,
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            sentence,
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: isMidnight
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Container(
            height: 2,
            width: 40.w,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "CONVERT TO A QUESTION",
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
