import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PrefixSuffixDockingTerminal extends StatelessWidget {
  final int index;
  final String text;
  final Color primaryColor;
  final bool isDark;
  final Offset position;

  const PrefixSuffixDockingTerminal({
    super.key,
    required this.index,
    required this.text,
    required this.primaryColor,
    required this.isDark,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: screenSize.width / 2 + position.dx - 40.w,
      top: (screenSize.height * 0.6) / 2 + position.dy - 35.h,
      child: Container(
        width: 80.w,
        height: 70.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.1,
              child: Icon(Icons.hexagon_outlined, color: primaryColor, size: 50.r),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Container(
                  width: 25.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 1.5.seconds,
          )
          .shimmer(
            delay: (index * 150).ms,
            duration: 3.seconds,
            color: primaryColor.withValues(alpha: 0.2),
          ),
    );
  }
}
