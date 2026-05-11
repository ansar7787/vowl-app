import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ConsonantMouthTip extends StatelessWidget {
  final String? tip;
  final bool isDark;
  final bool isMidnight;

  const ConsonantMouthTip({
    super.key,
    this.tip,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tip == null || tip!.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.face_retouching_natural_rounded,
              color: Colors.white,
              size: 20.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MOUTH TIP",
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade700,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  tip!,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
