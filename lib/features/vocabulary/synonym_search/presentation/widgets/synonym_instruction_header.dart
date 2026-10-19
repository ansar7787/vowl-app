import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class SynonymInstructionHeader extends StatelessWidget {
  final Color color;
  final String instruction;
  final String? hint;
  final bool isCompact;

  const SynonymInstructionHeader({
    super.key,
    required this.color,
    this.instruction = "Find the matching synonym",
    this.hint,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final content = Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: BoxConstraints(maxWidth: 360.w),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16.w : 20.w,
              vertical: isCompact ? 8.h : 11.h,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? color.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  instruction,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 12.sp : 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.3,
                    height: 1.35,
                  ),
                ),
                if (hint != null && hint!.trim().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    hint!,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 11.sp : 12.sp,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.slate600,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return content;
    }

    return content
        .animate()
        .fadeIn(duration: 500.ms, curve: Curves.easeOutQuad)
        .slideY(
          begin: -0.15,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutQuad,
        );
  }
}
