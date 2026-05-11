import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class GrammarInstruction extends StatelessWidget {
  final String instruction;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;

  const GrammarInstruction({
    super.key,
    required this.instruction,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, color: primaryColor, size: 20.r),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              instruction,
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }
}
