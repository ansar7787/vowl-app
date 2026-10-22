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

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget iconWidget = Container(
      key: const Key('conflict_resolver_card_icon'),
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
    );

    if (!reduceMotion) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 2.seconds,
            curve: Curves.easeInOut,
          );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: emotionalColor.withValues(alpha: isDark ? 0.22 : 0.16),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : emotionalColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          SizedBox(height: 14.h),
          Text(
            scene,
            key: const Key('conflict_resolver_scene_text'),
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.45,
            ),
          ),
          SizedBox(height: 18.h),
          // Tension Meter
          Wrap(
            key: const Key('conflict_resolver_tension_meter'),
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              Text(
                "TENSION",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(
                width: 160.w,
                child: Row(
                  children: List.generate(10, (index) {
                    final isActive = index < escalationLevel;
                    final levelColor =
                        Color.lerp(
                          tokens.gameCorrect,
                          tokens.gameIncorrect,
                          index / 9,
                        ) ??
                        color;

                    return Expanded(
                      child: Container(
                        key: Key('conflict_resolver_tension_bar_$index'),
                        height: 5.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: isActive
                              ? levelColor
                              : (isDark ? Colors.white12 : Colors.black12),
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
