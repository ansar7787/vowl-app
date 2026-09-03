import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
        padding: EdgeInsets.symmetric(vertical: 8.h),
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
              context.tr('instructions.flashcards.tap_to_reveal', fallback: 'TAP CARD TO REVEAL'),
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
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _ActionBtn(
              label: context.tr('actions.again', fallback: 'AGAIN'),
              icon: Icons.keyboard_double_arrow_left_rounded,
              color: const Color(0xFFEF4444), // Premium Red
              isDark: isDark,
              onTap: isTransitioning ? null : onAgain,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _ActionBtn(
              label: context.tr('actions.got_it', fallback: 'GOT IT'),
              icon: Icons.keyboard_double_arrow_right_rounded,
              color: const Color(0xFF10B981), // Premium Green
              isDark: isDark,
              onTap: isTransitioning ? null : onGotIt,
              isRight: true,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isRight;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    this.onTap,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10), // Softer background
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5), // Softer border
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isRight) ...[
                Icon(icon, color: color, size: 20.r),
                SizedBox(width: 4.w),
              ],
              Flexible( // Added flexible to prevent ellipsis if translated text is long
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              if (isRight) ...[
                SizedBox(width: 4.w),
                Icon(icon, color: color, size: 20.r),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
