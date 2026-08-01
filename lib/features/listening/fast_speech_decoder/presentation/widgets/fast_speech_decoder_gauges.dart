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
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed_rounded, color: color, size: 16.r),
            SizedBox(width: 8.w),
            Text(
              "VELOCITY SENSOR",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          "${speed.toStringAsFixed(1)}X",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 36.sp,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
