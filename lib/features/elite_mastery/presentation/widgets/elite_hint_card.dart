import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class EliteHintCard extends StatelessWidget {
  final String? hintText;
  final bool isVisible;
  final VoidCallback onShowHint;
  final Color primaryColor;

  const EliteHintCard({
    super.key,
    required this.hintText,
    required this.isVisible,
    required this.onShowHint,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isVisible) {
      return ScaleButton(
        onTap: onShowHint,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_rounded, color: primaryColor, size: 20.r),
              SizedBox(width: 10.w),
              Text(
                "NEED A HINT?",
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GlassTile(
      borderRadius: BorderRadius.circular(24.r),
      padding: EdgeInsets.all(20.r),
      color: primaryColor.withValues(alpha: 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: primaryColor, size: 24.r),
              SizedBox(width: 12.w),
              Text(
                "EXPERT HINT",
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            hintText ?? "Try looking for context clues in the structure!",
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
