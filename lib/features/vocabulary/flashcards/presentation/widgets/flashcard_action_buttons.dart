import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
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
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;

    if (!isFlipped) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            reduceMotion
                ? Icon(
                    Icons.touch_app_rounded,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                    size: 24.r,
                  )
                : Icon(
                    Icons.touch_app_rounded,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                    size: 24.r,
                  )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(
                      begin: 2,
                      end: -2,
                      duration: 1.seconds,
                      curve: Curves.easeInOut,
                    ),
            SizedBox(height: 6.h),
            Text(
              context.tr(
                'instructions.flashcards.tap_to_reveal',
                fallback: 'Tap card to flip',
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? AppColors.slate300 : AppColors.slate600,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    }

    final buttonsRow = Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _ActionBtn(
              label: context.tr('actions.again', fallback: 'Again'),
              icon: Icons.keyboard_double_arrow_left_rounded,
              color: AppColors.red500,
              isDark: isDark,
              onTap: isTransitioning ? null : onAgain,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: _ActionBtn(
              label: context.tr('actions.got_it', fallback: 'Got It'),
              icon: Icons.keyboard_double_arrow_right_rounded,
              color: AppColors.emerald500,
              isDark: isDark,
              onTap: isTransitioning ? null : onGotIt,
              isRight: true,
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) return buttonsRow;
    return buttonsRow.animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
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
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isRight) ...[
                Icon(icon, color: color, size: 18.r),
                SizedBox(width: 6.w),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isRight) ...[
                SizedBox(width: 6.w),
                Icon(icon, color: color, size: 18.r),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
