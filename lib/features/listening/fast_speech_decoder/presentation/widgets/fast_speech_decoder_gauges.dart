import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FastSpeechDecoderGauges extends StatelessWidget {
  final double speed;
  final Color color;

  const FastSpeechDecoderGauges({
    super.key,
    required this.speed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed_rounded,
              color: color,
              size: 16.r,
            ),
            SizedBox(width: 8.w),
            Text(
              "PLAYBACK SPEED",
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.85),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          "${speed.toStringAsFixed(1)}X",
          textAlign: TextAlign.center,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
