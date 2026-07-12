import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class FlashcardActionButtons extends StatelessWidget {
  final bool isFlipped;
  final bool isTransitioning;
  final bool isDark;
  final VoidCallback onAgain;
  final VoidCallback onGotIt;

  const FlashcardActionButtons({
    super.key,
    required this.isFlipped,
    required this.isTransitioning,
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
                .animate(onPlay: (c) => c.repeat())
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

          final reviewButton = _ActionButton(
            label: 'REVIEW',
            icon: Icons.refresh_rounded,
            color: isDark
                ? Colors.red.withValues(alpha: 0.16)
                : Colors.red.withValues(alpha: 0.10),
            textColor: isDark ? Colors.redAccent : Colors.red,
            onTap: isTransitioning ? null : onAgain,
          );

          final masterButton = _ActionButton(
            label: 'MASTER',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF22C55E),
            textColor: Colors.white,
            onTap: isTransitioning ? null : onGotIt,
          );

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                reviewButton,
                SizedBox(height: 12.h),
                masterButton,
              ],
            ).animate().fadeIn().slideY(begin: 0.1);
          }

          return Row(
            children: [
              Expanded(child: reviewButton),
              SizedBox(width: 14.w),
              Expanded(child: masterButton),
            ],
          ).animate().fadeIn().slideY(begin: 0.1);
        },
      ),
    );
  }
}

// ─── Private sub-widget ───────────────────────────────────────────────────────

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
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: ScaleButton(
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: onTap == null
                      ? textColor.withValues(alpha: 0.5)
                      : textColor,
                  size: 24.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: onTap == null
                        ? textColor.withValues(alpha: 0.5)
                        : textColor,
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
