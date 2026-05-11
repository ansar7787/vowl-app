import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TenseTimeline extends StatelessWidget {
  final String? targetTense;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;

  const TenseTimeline({
    super.key,
    this.targetTense,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    // Logic to determine which segment to highlight
    final tense = targetTense?.toLowerCase() ?? "";
    bool isPast = tense.contains("past");
    bool isPresent = tense.contains("present") || tense.contains("habit");
    bool isFuture = tense.contains("future");

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              color: primaryColor.withValues(alpha: 0.6),
              size: 14.r,
            ),
            SizedBox(width: 8.w),
            Text(
              "TIME LOGIC INDICATOR",
              style: GoogleFonts.shareTechMono(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: primaryColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: isMidnight
                ? Colors.black.withValues(alpha: 0.2)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isMidnight
                  ? primaryColor.withValues(alpha: 0.2)
                  : primaryColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildTimeSegment("PAST", isPast),
                  _buildConnector(isPast || isPresent),
                  _buildTimeSegment("PRESENT", isPresent),
                  _buildConnector(isPresent || isFuture),
                  _buildTimeSegment("FUTURE", isFuture),
                ],
              ),
              if (targetTense != null)
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: Text(
                    targetTense!,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn().scale(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSegment(String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
                width: 12.r,
                height: 12.r,
                decoration: BoxDecoration(
                  color: isActive
                      ? primaryColor
                      : (isDark ? Colors.white10 : Colors.black12),
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .scale(begin: const Offset(0.8, 0.8)),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              color: isActive
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white24 : Colors.black26),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isHighlighted) {
    return Container(
      width: 40.w,
      height: 2.h,
      margin: EdgeInsets.only(bottom: 20.h), // Align with dots
      color: isHighlighted
          ? primaryColor.withValues(alpha: 0.3)
          : (isDark ? Colors.white10 : Colors.black12),
    );
  }
}
