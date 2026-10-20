import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class ReadAndMatchTerminal extends StatelessWidget {
  final String text;
  final bool isSource;
  final Color color;
  final bool isDark;
  final bool isMatched;
  final bool isActive;
  final bool shouldPulse;
  final VoidCallback onTap;

  const ReadAndMatchTerminal({
    super.key,
    required this.text,
    required this.isSource,
    required this.color,
    required this.isDark,
    required this.isMatched,
    required this.isActive,
    this.shouldPulse = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanText = text.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
    final isLong = cleanText.length > 32;
    final isMedium = cleanText.length > 18;

    final double fontSize = isLong
        ? 13.sp
        : (isMedium ? 13.5.sp : 14.5.sp);

    final FontWeight fontWeight = isSource
        ? (isLong ? FontWeight.w500 : FontWeight.w600)
        : (isLong ? FontWeight.w400 : FontWeight.w500);

    // Background color
    final Color bgColor = isMatched
        ? color.withValues(alpha: isDark ? 0.16 : 0.08)
        : (isActive
            ? color.withValues(alpha: isDark ? 0.22 : 0.12)
            : (isDark
                ? const Color(0xFF1E202E)
                : Colors.white));

    // Border color and width
    final Color borderColor = isMatched || isActive
        ? color
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFE2E8F0));

    final double borderWidth = (isMatched || isActive) ? 2.0 : 1.5;

    // Text color
    final Color textColor = isMatched || isActive
        ? (isDark ? Colors.white : color)
        : (isDark
            ? Colors.white.withValues(alpha: 0.92)
            : const Color(0xFF1E293B));

    return Semantics(
      button: true,
      label: cleanText,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 52.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
            boxShadow: [
              if (isMatched || isActive)
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.35 : 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              else
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            cleanText,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: fontSize,
              height: 1.35,
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        )
            .animate(
              target: shouldPulse ? 1 : 0,
              onPlay: (controller) {
                if (!VowlMotion.shouldReduceMotion(context)) {
                  controller.repeat(reverse: true);
                }
              },
            )
            .scaleXY(
              begin: 1.0,
              end: 1.015,
              duration: 1.2.seconds,
              curve: Curves.easeInOutSine,
            ),
      ),
    );
  }
}
