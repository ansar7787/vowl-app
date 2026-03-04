import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';

class ImOptionButton extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final ThemeResult theme;
  final VoidCallback onTap;

  const ImOptionButton({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color? cardColor;
    Color borderColor = theme.primaryColor.withValues(alpha: 0.15);

    if (showResult) {
      if (isCorrect) {
        cardColor = const Color(0xFF10B981);
        borderColor = const Color(0xFF10B981);
      } else if (isSelected) {
        cardColor = const Color(0xFFF43F5E);
        borderColor = const Color(0xFFF43F5E);
      }
    } else if (isSelected) {
      borderColor = theme.primaryColor;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: showResult ? null : onTap,
        child: GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          borderRadius: BorderRadius.circular(24.r),
          color:
              cardColor?.withValues(alpha: 0.2) ??
              (isSelected
                  ? theme.primaryColor.withValues(alpha: 0.1)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white)),
          borderColor: isSelected || showResult
              ? borderColor
              : (isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.05)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: GoogleFonts.outfit(
                    fontSize: 17.sp,
                    fontWeight: isSelected || (showResult && isCorrect)
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color:
                        cardColor ??
                        (isSelected
                            ? theme.primaryColor
                            : (isDark ? Colors.white70 : Colors.black87)),
                  ),
                ),
              ),
              if (showResult && isCorrect)
                Icon(Icons.check_circle_rounded, color: cardColor, size: 24.r)
              else if (showResult && isSelected && !isCorrect)
                Icon(Icons.cancel_rounded, color: cardColor, size: 24.r)
              else
                Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryColor
                          : (isDark ? Colors.white12 : Colors.black12),
                      width: 2,
                    ),
                    color: isSelected
                        ? theme.primaryColor.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, curve: Curves.easeOut);
  }
}
