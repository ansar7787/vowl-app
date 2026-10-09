import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConflictResolverConflictCard extends StatelessWidget {
  final String scene;
  final int escalationLevel;
  final Color color;
  final bool isDark;

  const ConflictResolverConflictCard({
    super.key,
    required this.scene,
    required this.escalationLevel,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    Color emotionalColor = color;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: emotionalColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: emotionalColor.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: emotionalColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_rounded,
              color: emotionalColor,
              size: 24.r,
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 2.seconds,
            curve: Curves.easeInOut,
          ),
          SizedBox(height: 16.h),
          Text(
            scene,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),
          // Tension Meter
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              Text(
                "TENSION",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(
                width: 160.w,
                child: Row(
                  children: List.generate(10, (index) {
                    final isActive = index < escalationLevel;
                    final levelColor = Color.lerp(
                      tokens.gameCorrect,
                      tokens.gameIncorrect,
                      index / 9,
                    ) ?? color;

                    return Expanded(
                      child: Container(
                        height: 4.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: isActive
                              ? levelColor
                              : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(4.r),
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
