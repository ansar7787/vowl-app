import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SpeechDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const SpeechDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    switch (difficulty) {
      case 1:
        label = 'WORD RANK: NOVICE';
        color = const Color(0xFFFBBF24); // Amber
        break;
      case 2:
        label = 'WORD RANK: EXPERT';
        color = const Color(0xFFF97316); // Orange
        break;
      case 3:
      default:
        label = 'WORD RANK: MASTER';
        color = const Color(0xFFEF4444); // Red
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
