import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';

class SsOptionButton extends StatelessWidget {
  final String option;
  final int index;
  final bool isSelected;
  final bool isEliminated;
  final bool isCorrect;
  final bool hasSubmitted;
  final Color primaryColor;
  final VoidCallback onTap;

  const SsOptionButton({
    super.key,
    required this.option,
    required this.index,
    required this.isSelected,
    required this.isEliminated,
    required this.isCorrect,
    required this.hasSubmitted,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Logic to highlight the stressed syllable from the JSON string (e.g., "ho-TEL")
    final parts = option.split('-');

    return ScaleButton(
      onTap: isEliminated || hasSubmitted ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: _getBgColor(isDark),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _getBorderColor(), width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(parts.length, (i) {
                final part = parts[i];
                final isStressed =
                    part == part.toUpperCase() && part.length > 1;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      part.toLowerCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 20.sp,
                        fontWeight: isStressed
                            ? FontWeight.w900
                            : FontWeight.w500,
                        color: _getTextColor(isDark, isStressed),
                        letterSpacing: 1,
                      ),
                    ),
                    if (i < parts.length - 1)
                      Text(
                        "-",
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                      ),
                  ],
                );
              }),
              if (hasSubmitted && isSelected) ...[
                SizedBox(width: 12.w),
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                  size: 24.r,
                ).animate().scale().shake(),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }

  Color _getBgColor(bool isDark) {
    if (isEliminated) return isDark ? Colors.white10 : Colors.black12;
    if (isSelected) return primaryColor.withValues(alpha: 0.15);
    return isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
  }

  Color _getBorderColor() {
    if (hasSubmitted && isSelected) {
      return isCorrect ? Colors.greenAccent : Colors.redAccent;
    }
    if (isSelected) return primaryColor;
    return Colors.transparent;
  }

  Color _getTextColor(bool isDark, bool isStressed) {
    if (isEliminated) return isDark ? Colors.white24 : Colors.black26;
    if (isStressed) return primaryColor;
    return isDark ? Colors.white70 : Colors.black87;
  }
}
