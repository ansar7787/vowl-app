import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SpeedVarianceSpeedToggle extends StatelessWidget {
  final bool isNatural;
  final ValueChanged<bool> onChanged;
  final Color primaryColor;
  final bool isDark;

  const SpeedVarianceSpeedToggle({
    super.key,
    required this.isNatural,
    required this.onChanged,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.w,
      height: 44.h,
      decoration: BoxDecoration(
        color: isDark ? primaryColor.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            left: isNatural ? 2.w : 138.w,
            top: 2.h,
            bottom: 2.h,
            width: 136.w,
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ScaleButton(
                  onTap: () => onChanged(true),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 16.r,
                          color: isNatural ? primaryColor : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "NATURAL",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: isNatural ? primaryColor : (isDark ? Colors.white54 : Colors.black54),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ScaleButton(
                  onTap: () => onChanged(false),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hearing_rounded,
                          size: 16.r,
                          color: !isNatural ? primaryColor : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "CLEAR",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: !isNatural ? primaryColor : (isDark ? Colors.white54 : Colors.black54),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }
}
