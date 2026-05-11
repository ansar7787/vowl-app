import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AgreementDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const AgreementDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    switch (difficulty) {
      case 1:
        label = 'DUAL HARMONY';
        color = const Color(0xFF0EA5E9); // Cyan
        break;
      case 2:
        label = 'TRIPLE HARMONY';
        color = const Color(0xFF6366F1); // Indigo
        break;
      case 3:
      default:
        label = 'TOTAL HARMONY';
        color = const Color(0xFFA855F7); // Purple
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 10.r, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9.sp,
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
