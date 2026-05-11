import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CorrectionDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const CorrectionDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    switch (difficulty) {
      case 1:
        label = 'MINOR';
        color = const Color(0xFFFBBF24); // Amber
        break;
      case 2:
        label = 'MODERATE';
        color = const Color(0xFFF97316); // Orange
        break;
      case 3:
      default:
        label = 'SEVERE';
        color = const Color(0xFFEF4444); // Red
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.report_problem_rounded, size: 12.r, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
