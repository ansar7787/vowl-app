import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ArticleDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const ArticleDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    switch (difficulty) {
      case 1:
        label = 'BASIC';
        color = const Color(0xFF6366F1); // Indigo
        break;
      case 2:
        label = 'INTERMEDIATE';
        color = const Color(0xFF8B5CF6); // Violet
        break;
      case 3:
      default:
        label = 'ADVANCED';
        color = const Color(0xFFD946EF); // Fuchsia
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9.sp,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
