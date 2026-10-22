import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShadowingChallengeSpeedSlider extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onChanged;
  final Color color;
  final bool isDark;

  const ShadowingChallengeSpeedSlider({
    super.key,
    required this.speed,
    required this.onChanged,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.05)
            : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.speed_rounded,
                    size: 16.r,
                    color: color,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Playback Speed",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  "${speed.toStringAsFixed(2)}x",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 3.5.h,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
            ),
            child: Slider(
              key: const ValueKey('shadowing_speed_slider'),
              value: speed,
              min: 0.75,
              max: 1.25,
              divisions: 2,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
