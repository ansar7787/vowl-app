import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ReadAndAnswerDepthMeter extends StatelessWidget {
  final double depth;
  final Color color;

  const ReadAndAnswerDepthMeter({
    super.key,
    required this.depth,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16.w,
      top: 100.h,
      bottom: 100.h,
      child: Column(
        children: [
          Text(
            "${(depth / 10).toInt()}M", 
            style: GoogleFonts.shareTechMono(color: color, fontSize: 14.sp),
          ),
          Expanded(
            child: Container(
              width: 4.w,
              margin: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  FractionallySizedBox(
                    heightFactor: (depth / 1000).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 16.r),
        ],
      ),
    );
  }
}
