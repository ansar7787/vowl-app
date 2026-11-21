import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Tactile, responsive word tile for the Cluster Fusion matrix.
class TopicFusionTile extends StatelessWidget {
  final String word;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const TopicFusionTile({
    super.key,
    required this.word,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? accentColor.withValues(alpha: isDark ? 0.28 : 0.18)
        : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04));

    final borderColor = isSelected
        ? accentColor
        : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08));

    final textColor = isSelected
        ? accentColor
        : (isDark ? Colors.white : const Color(0xFF1E293B));

    return Semantics(
      button: true,
      label: '$word, ${isSelected ? "selected" : "not selected"}',
      child: ScaleButton(
        onTap: onTap,
        scaleDown: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 10.r,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
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
      ),
    );
  }
}
