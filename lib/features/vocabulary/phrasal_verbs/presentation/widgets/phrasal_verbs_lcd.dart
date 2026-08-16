import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class PhrasalVerbsLcd extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const PhrasalVerbsLcd({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.9.sw,
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar_rounded, size: 12.sp, color: color),
                  SizedBox(width: 8.w),
                  AutoSizeText(
                    "DECRYPTING TARGET",
                    maxLines: 1,
                    minFontSize: 4,
                    stepGranularity: 0.5,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(duration: 1.seconds),
          SizedBox(height: 10.h),
          AutoSizeText(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 4,
            stepGranularity: 0.5,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
