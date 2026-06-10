import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class FlashcardActionButtons extends StatelessWidget {
  final bool isFlipped;
  final bool isTransitioning;
  final ThemeResult theme;
  final bool isDark;
  final VoidCallback onAgain;
  final VoidCallback onGotIt;

  const FlashcardActionButtons({
    super.key,
    required this.isFlipped,
    required this.isTransitioning,
    required this.theme,
    required this.isDark,
    required this.onAgain,
    required this.onGotIt,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFlipped) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                  Icons.touch_app_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 30.r,
                )
                .animate(onPlay: (controller) => controller.repeat())
                .moveY(
                  begin: 4,
                  end: -4,
                  duration: 1.seconds,
                  curve: Curves.easeInOut,
                ),
            SizedBox(height: 8.h),
            Text(
              'TAP CARD TO REVEAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w900,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 320;

          final buttons = [
            _ActionButton(
              label: 'REVIEW',
              icon: Icons.refresh_rounded,
              color: isDark
                  ? Colors.red.withValues(alpha: 0.16)
                  : Colors.red.withValues(alpha: 0.10),
              textColor: isDark ? Colors.redAccent : Colors.red,
              onTap: isTransitioning ? null : onAgain,
            ),
            _ActionButton(
              label: 'MASTER',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF22C55E),
              textColor: Colors.white,
              onTap: isTransitioning ? null : onGotIt,
            ),
          ];

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buttons[0],
                SizedBox(height: 12.h),
                buttons[1],
              ],
            ).animate().fadeIn().slideY(begin: 0.1);
          }

          return Row(
            children: [
              Expanded(child: buttons[0]),
              SizedBox(width: 14.w),
              Expanded(child: buttons[1]),
            ],
          ).animate().fadeIn().slideY(begin: 0.1);
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 54.h),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: 0.05) : color,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: onTap == null
                ? textColor.withValues(alpha: 0.1)
                : textColor.withValues(alpha: 0.25),
          ),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1.0,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 24.r),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
