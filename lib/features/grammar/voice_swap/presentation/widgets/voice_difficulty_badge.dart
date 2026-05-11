import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class VoiceDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const VoiceDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    switch (difficulty) {
      case 1:
        label = 'DIRECT';
        color = const Color(0xFF10B981); // Emerald
        break;
      case 2:
        label = 'INDIRECT';
        color = const Color(0xFFF59E0B); // Amber
        break;
      case 3:
      default:
        label = 'OBSCURE';
        color = const Color(0xFF6366F1); // Indigo
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_rounded, size: 12.r, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
