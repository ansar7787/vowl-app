import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Tactile, responsive word tile for the Cluster Fusion matrix with
/// selection indicators, elevation lift, and error feedback.
class TopicFusionTile extends StatelessWidget {
  final String word;
  final bool isSelected;
  final bool isError;
  final VoidCallback onTap;
  final Color accentColor;

  const TopicFusionTile({
    super.key,
    required this.word,
    required this.isSelected,
    this.isError = false,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isError) {
      bgColor = AppColors.rose500.withValues(alpha: isDark ? 0.35 : 0.2);
      borderColor = AppColors.rose500;
      textColor = isDark ? Colors.white : AppColors.rose500;
    } else if (isSelected) {
      bgColor = accentColor.withValues(alpha: isDark ? 0.28 : 0.18);
      borderColor = accentColor;
      textColor = accentColor;
    } else {
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04);
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08);
      textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    }

    return Semantics(
      button: true,
      label: '$word, ${isSelected ? "selected" : "not selected"}',
      child: ScaleButton(
        onTap: onTap,
        scaleDown: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor,
              width: (isSelected || isError) ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isError ? AppColors.rose500 : accentColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 10.r,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: AutoSizeText(
                  word,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  minFontSize: 11,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (isSelected && !isError)
                Positioned(
                  top: -4.h,
                  right: -4.w,
                  child: Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 4.r,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
