import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicBatchCounter extends StatelessWidget {
  final int count;
  final int total;
  final Color color;

  const TopicBatchCounter({
    super.key,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), // Minimal glass
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "BATCH PROGRESS: $count / $total",
            style: GoogleFonts.shareTechMono(
              color: color.withValues(alpha: 0.8),
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(total, (i) {
              bool isFilled = i < count;
              return Container(
                width: 12.w,
                height: 3.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: isFilled ? color : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ).animate(target: isFilled ? 1 : 0).shimmer(duration: 1.seconds);
            }),
          ),
        ],
      ),
    );
  }
}
