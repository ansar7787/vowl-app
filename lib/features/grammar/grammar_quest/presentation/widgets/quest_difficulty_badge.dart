import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const QuestDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    switch (difficulty) {
      case 1:
        label = 'L1-SECURE';
        color = const Color(0xFF10B981); // Emerald
        break;
      case 2:
        label = 'L2-CAUTION';
        color = Colors.orangeAccent;
        break;
      case 3:
      default:
        label = 'L3-CRITICAL';
        color = const Color(0xFFF43F5E); // Rose
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security_rounded, size: 14.r, color: color),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              fontSize: 11.sp,
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
