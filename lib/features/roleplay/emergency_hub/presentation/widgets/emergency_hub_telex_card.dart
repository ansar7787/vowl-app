import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmergencyHubTelexCard extends StatelessWidget {
  final String telex;
  final int urgencyLevel;
  final bool isDark;

  const EmergencyHubTelexCard({
    super.key,
    required this.telex,
    required this.urgencyLevel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: tokens.gameIncorrect.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.gameIncorrect.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: tokens.gameIncorrect.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: tokens.gameIncorrect,
                      size: 20.r,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 1.2.seconds,
                    curve: Curves.easeInOut,
                  ),
              SizedBox(width: 10.w),
              Text(
                "CRITICAL INCOMING HAZARD ALERT",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: tokens.gameIncorrect,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            telex,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.35,
            ),
          ),
          SizedBox(height: 16.h),
          Divider(
            color: tokens.gameIncorrect.withValues(alpha: 0.15),
            thickness: 1,
            height: 1,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text(
                "URGENCY LEVEL",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Row(
                  children: List.generate(5, (index) {
                    final isActive = index < urgencyLevel;
                    return Expanded(
                      child: Container(
                        height: 6.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (urgencyLevel >= 4
                                    ? tokens.gameIncorrect
                                    : (urgencyLevel >= 3
                                          ? Colors.orangeAccent
                                          : Colors.yellowAccent))
                              : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(4.r),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color:
                                        (urgencyLevel >= 4
                                                ? tokens.gameIncorrect
                                                : Colors.orangeAccent)
                                            .withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
