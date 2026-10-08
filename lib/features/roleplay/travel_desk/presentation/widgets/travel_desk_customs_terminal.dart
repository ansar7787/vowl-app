import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TravelDeskCustomsTerminal extends StatelessWidget {
  final String prompt;
  final Color color;
  final bool isDark;

  const TravelDeskCustomsTerminal({
    super.key,
    required this.prompt,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shadowColor: color.withValues(alpha: 0.4),
      color: isDark ? AppColors.deepDark : Colors.white,
      surfaceTintColor: color.withValues(alpha: 0.05),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final reduceMotion = MediaQuery.disableAnimationsOf(context);
                Widget icon = Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.record_voice_over_rounded,
                    color: color,
                    size: 26.r,
                  ),
                );

                if (!reduceMotion) {
                  icon = icon
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 2.seconds,
                        curve: Curves.easeInOutSine,
                      );
                }
                return icon;
              },
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TRAVELER REQUEST",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      color: color,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "\"$prompt\"",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
