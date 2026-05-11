import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TenseDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const TenseDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    switch (difficulty) {
      case 1:
        label = 'LINEAR';
        color = const Color(0xFF22C55E); // Green
        break;
      case 2:
        label = 'ELAPSED';
        color = const Color(0xFF3B82F6); // Blue
        break;
      case 3:
      default:
        label = 'CONVOLUTED';
        color = const Color(0xFF8B5CF6); // Violet
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timeline_rounded, size: 12.r, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
