import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ReorderDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const ReorderDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    switch (difficulty) {
      case 1:
        label = 'LINEAR';
        color = Colors.lightBlue;
        break;
      case 2:
        label = 'COMPLEX';
        color = Colors.teal;
        break;
      case 3:
      default:
        label = 'HIERARCHICAL';
        color = Colors.indigo;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
