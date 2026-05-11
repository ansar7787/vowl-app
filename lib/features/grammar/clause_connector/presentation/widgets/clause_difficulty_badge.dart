import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ClauseDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const ClauseDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final String label;
    final IconData icon;
    final Color color;

    switch (difficulty) {
      case 1:
        label = 'FOUNDATION';
        icon = Icons.layers_rounded;
        color = Colors.cyan;
        break;
      case 2:
        label = 'INTERMEDIATE';
        icon = Icons.grid_view_rounded;
        color = Colors.orange;
        break;
      case 3:
      default:
        label = 'ADVANCED';
        icon = Icons.architecture_rounded;
        color = Colors.deepPurpleAccent;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(20.r),
        ),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
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
