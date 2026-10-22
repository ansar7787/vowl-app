import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// A chip that displays a dialogue response choice.
class SmartReplyChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPremium;
  final bool isSelected;
  final Color? primaryColor;

  const SmartReplyChip({
    super.key,
    required this.text,
    required this.onTap,
    this.isPremium = false,
    this.isSelected = false,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = primaryColor ?? AppColors.violet500;

    final semanticLabel =
        'Response option: $text${!isPremium ? ". Watch ad to unlock." : ""}';

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(right: 12.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.black.withValues(alpha: 0.12)),
              width: isSelected ? 1.8 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.chat_bubble_outline_rounded,
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.white60 : Colors.black45),
                size: 15.r,
              ),
              SizedBox(width: 8.w),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : activeColor)
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              if (!isPremium) ...[
                SizedBox(width: 8.w),
                Icon(
                  Icons.play_circle_outline_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 14.r,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
