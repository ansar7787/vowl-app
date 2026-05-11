import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class ClauseCard extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool isMidnight;
  final Color primaryColor;

  const ClauseCard({
    super.key,
    required this.text,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      borderRadius: BorderRadius.circular(20.r),
      borderColor: primaryColor.withValues(alpha: 0.2),
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.04),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
