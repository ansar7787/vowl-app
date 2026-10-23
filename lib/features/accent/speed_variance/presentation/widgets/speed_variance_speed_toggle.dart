import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Toggle pill allowing switching between natural conversational and enunciated clear speed.
class SpeedVarianceSpeedToggle extends StatelessWidget {
  /// Whether natural conversational speed is currently active (false for clear speed).
  final bool isNatural;

  /// Callback executed when the learner toggles the speed mode.
  final ValueChanged<bool> onChanged;

  /// Theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [SpeedVarianceSpeedToggle] widget.
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
      width: 290.w,
      height: 44.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: isDark
            ? primaryColor.withValues(alpha: 0.1)
            : primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: isNatural ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(19.r),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ScaleButton(
                  key: const ValueKey('speed_toggle_natural'),
                  onTap: () => onChanged(true),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 16.r,
                          color: isNatural
                              ? primaryColor
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "Natural",
                          softWrap: false,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isNatural
                                ? primaryColor
                                : (isDark ? Colors.white60 : Colors.black54),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ScaleButton(
                  key: const ValueKey('speed_toggle_clear'),
                  onTap: () => onChanged(false),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hearing_rounded,
                          size: 16.r,
                          color: !isNatural
                              ? primaryColor
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "Clear",
                          softWrap: false,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: !isNatural
                                ? primaryColor
                                : (isDark ? Colors.white60 : Colors.black54),
                            letterSpacing: 0.3,
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
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15);
  }
}
