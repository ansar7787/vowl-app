import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class WordBuilderTile extends StatelessWidget {
  final String word;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;
  final bool isDragged;

  const WordBuilderTile({
    super.key,
    required this.word,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
    this.isDragged = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDragged
                ? primaryColor.withValues(alpha: 0.8)
                : (isMidnight
                    ? Colors.white.withValues(alpha: 0.05)
                    : (isDark ? Colors.white10 : Colors.white)),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDragged
                  ? Colors.white54
                  : primaryColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : primaryColor).withValues(
                  alpha: 0.1,
                ),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            word,
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: isDragged
                  ? Colors.white
                  : (isDark ? Colors.white : primaryColor),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
