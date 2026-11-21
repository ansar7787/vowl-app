import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Clean, tactile word tile with standard typography, balanced weights,
/// selection indicator, and long-press definition peek.
class TopicFusionTile extends StatelessWidget {
  final String word;
  final bool isSelected;
  final bool isError;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color accentColor;

  const TopicFusionTile({
    super.key,
    required this.word,
    required this.isSelected,
    this.isError = false,
    required this.onTap,
    this.onLongPress,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isError) {
      bgColor = AppColors.rose500.withValues(alpha: isDark ? 0.3 : 0.15);
      borderColor = AppColors.rose500;
      textColor = isDark ? Colors.white : AppColors.rose500;
    } else if (isSelected) {
      bgColor = accentColor.withValues(alpha: isDark ? 0.22 : 0.14);
      borderColor = accentColor;
      textColor = accentColor;
    } else {
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03);
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.07);
      textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    }

    return Semantics(
      button: true,
      label: '$word, ${isSelected ? "selected" : "not selected"}',
      child: ScaleButton(
        onTap: onTap,
        onLongPress: onLongPress,
        scaleDown: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: borderColor,
              width: (isSelected || isError) ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isError ? AppColors.rose500 : accentColor)
                          .withValues(alpha: 0.2),
                      blurRadius: 8.r,
                      offset: const Offset(0, 2),
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
                    fontSize: 14.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              if (isSelected && !isError)
                Positioned(
                  top: -2.h,
                  right: -2.w,
                  child: Container(
                    width: 7.r,
                    height: 7.r,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
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
